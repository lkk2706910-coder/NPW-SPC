using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;

// TF1 NPW weekly alarm report. Fully standalone (no inheritance) so it can be
// deployed in its own folder / app independent of the TF2 page. No AI.
//
// Routes:
//   GET  NPW_Alarm_TF1.aspx              -> renders the page
//   GET  NPW_Alarm_TF1.aspx?op=alarm     -> raw weekly rows
//   GET  NPW_Alarm_TF1.aspx?op=chartdata -> SPC trend series
//   GET  NPW_Alarm_TF1.aspx?op=profileimg-> single RAW contour image url
//   GET  NPW_Alarm_TF1.aspx?op=data      -> generic table query
//
// NOTE: keep this file pure ASCII. Some servers compile .cs as Big5/CP950,
// which can eat the newline after a non-ASCII char and break compilation.
public partial class NPW_Alarm_TF1 : Page
{
    private const string ChartTable = "GPTDB_USPC.dbo.TF1_NPW_CHART";

    protected void Page_Load(object sender, EventArgs e)
    {
        string opStr = Request.QueryString["op"];
        if (string.Equals(opStr, "data", StringComparison.OrdinalIgnoreCase))
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            try { HandleData(); }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(ex.Message) + "\"}");
            }
            Response.End();
            return;
        }
        if (string.Equals(opStr, "alarm", StringComparison.OrdinalIgnoreCase))
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            try { HandleAlarm(); }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(ex.Message) + "\"}");
            }
            Response.End();
            return;
        }
        if (string.Equals(opStr, "chartdata", StringComparison.OrdinalIgnoreCase))
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            try { HandleChartData(); }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(ex.Message) + "\"}");
            }
            Response.End();
            return;
        }
        if (string.Equals(opStr, "profileimg", StringComparison.OrdinalIgnoreCase))
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            try { HandleProfileImg(); }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(ex.Message) + "\"}");
            }
            Response.End();
            return;
        }
        // Otherwise fall through to render the page.
    }

    // ISO week number (for the W## label).
    private static int IsoWeek(DateTime d)
    {
        var cal = System.Globalization.CultureInfo.InvariantCulture.Calendar;
        DayOfWeek day = cal.GetDayOfWeek(d);
        if (day >= DayOfWeek.Monday && day <= DayOfWeek.Wednesday) d = d.AddDays(3);
        return cal.GetWeekOfYear(d, System.Globalization.CalendarWeekRule.FirstFourDayWeek, DayOfWeek.Monday);
    }

    // Raw weekly rows for the NPW alarm report. ?date=YYYY-MM-DD (any day in the
    // week, defaults to today). The browser does the aggregation.
    //   - week range: Tuesday..Monday (bucketed by UPDATE_TIME)
    //   - ADDER / NON-ADDER: CHART_TYPE 'C-C' / 'XBAR'
    //   - Entity: PROCESSUNIT prefix before '-' (only NISACVD / SACVD shown)
    //   - exclude Engineering: CHART_DESC <> 'Engineering'
    //   - MONITOR_TYPE IN (NORMAL, PM)
    //   - Alarm: ALARM_COUNT >= 1 (decided on the client)
    private void HandleAlarm()
    {
        DateTime refDate;
        if (!DateTime.TryParse(Request.QueryString["date"], out refDate)) refDate = DateTime.Today;
        int diff = (((int)refDate.DayOfWeek) - ((int)DayOfWeek.Tuesday) + 7) % 7;
        DateTime weekStart = refDate.Date.AddDays(-diff);   // Tuesday
        DateTime weekEndExcl = weekStart.AddDays(7);        // next Tuesday (exclusive)
        DateTime weekEnd = weekStart.AddDays(6);            // Monday

        var days = new List<string>();
        for (int i = 0; i < 7; i++) days.Add(weekStart.AddDays(i).ToString("yyyy-MM-dd"));

        string sql =
            "SELECT PROCESSUNIT, CONVERT(varchar(10), UPDATE_TIME, 23) AS UPDATE_TIME, " +
            "MONITOR_TYPE, CHART_TYPE, CHART_NAME, CHART_ID, CHART_SEQ, CHART_DESC, ALARM_COUNT, MEASUREPU, MEAN_VALUE, WAFER, PARAMETER " +
            "FROM " + ChartTable + " WITH (NOLOCK) " +
            "WHERE UPDATE_TIME >= @p0 AND UPDATE_TIME < @p1 " +
            "AND MONITOR_TYPE IN ('NORMAL','PM') " +
            "AND ISNULL(CHART_DESC,'') <> 'Engineering' " +
            "AND CHART_TYPE IN ('C-C','XBAR') " +
            "AND (PROCESSUNIT LIKE 'NISACVD%' OR PROCESSUNIT LIKE 'SACVD%')";
        var rows = QueryRows(sql, weekStart, weekEndExcl);

        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Response.Write(ser.Serialize(new Dictionary<string, object> {
            { "ok", true },
            { "week", new Dictionary<string, object> {
                { "label", "W" + IsoWeek(weekStart) },
                { "start", weekStart.ToString("yyyy-MM-dd") },
                { "end", weekEnd.ToString("yyyy-MM-dd") },
                { "days", days }
            }},
            { "rows", rows }
        }));
    }

    // SPC trend series for the inline chart thumbnails. ?cids=ID1,ID2,...
    private void HandleChartData()
    {
        string cidsRaw = (Request.QueryString["cids"] ?? "").Trim();
        if (cidsRaw.Length == 0)
        {
            Response.Write("{\"ok\":true,\"series\":{}}");
            return;
        }
        var ids = new List<string>();
        foreach (var part in cidsRaw.Split(','))
        {
            string p = part.Trim();
            if (p.Length > 0 && ids.Count < 60 && !ids.Contains(p)) ids.Add(p);
        }

        int days;
        if (!int.TryParse(Request.QueryString["days"], out days) || days <= 0 || days > 400) days = 60;
        DateTime end;
        if (!DateTime.TryParse(Request.QueryString["end"], out end)) end = DateTime.Today;
        end = end.Date.AddDays(1);
        DateTime start = end.AddDays(-days);

        var args = new List<object>();
        var ph = new List<string>();
        foreach (var id in ids) { ph.Add("@p" + args.Count); args.Add(id); }
        int pStart = args.Count; args.Add(start);
        int pEnd = args.Count; args.Add(end);

        string sql =
            "SELECT CHART_ID, CHART_SEQ, CONVERT(varchar(19), UPDATE_TIME, 120) AS D, " +
            "XBAR, SIGMA, UCL, LCL, AVG1STD, AVG_1STD, AVG2STD, AVG_2STD, MEAN_VALUE, ALARM_COUNT, LOT, WAFER " +
            "FROM " + ChartTable + " WITH (NOLOCK) " +
            "WHERE CHART_ID IN (" + string.Join(",", ph) + ") " +
            "AND UPDATE_TIME >= @p" + pStart + " AND UPDATE_TIME < @p" + pEnd + " " +
            "ORDER BY CHART_ID, UPDATE_TIME";
        var rows = QueryRows(sql, args.ToArray());

        var series = new Dictionary<string, object>();
        foreach (var row in rows)
        {
            string cid = Convert.ToString(row["CHART_ID"]);
            List<object> list;
            object existing;
            if (series.TryGetValue(cid, out existing)) list = (List<object>)existing;
            else { list = new List<object>(); series[cid] = list; }
            list.Add(new Dictionary<string, object> {
                { "d", row["D"] },
                { "seq", row["CHART_SEQ"] },
                { "xbar", row["XBAR"] },
                { "sigma", row["SIGMA"] },
                { "ucl", row["UCL"] },
                { "lcl", row["LCL"] },
                { "avg1", row["AVG1STD"] },
                { "avgn1", row["AVG_1STD"] },
                { "avg2", row["AVG2STD"] },
                { "avgn2", row["AVG_2STD"] },
                { "mean", row["MEAN_VALUE"] },
                { "alarm", row["ALARM_COUNT"] },
                { "lot", row["LOT"] },
                { "wafer", row["WAFER"] }
            });
        }

        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Response.Write(ser.Serialize(new Dictionary<string, object> { { "ok", true }, { "series", series } }));
    }

    // Generic read from the source table. ?area=TF1 &pu=NISACVD &top=200
    private void HandleData()
    {
        string area = (Request.QueryString["area"] ?? "").Trim();
        string pu = (Request.QueryString["pu"] ?? "").Trim();
        int top;
        if (!int.TryParse(Request.QueryString["top"], out top) || top <= 0 || top > 5000) top = 200;

        var conds = new List<string>();
        var args = new List<object>();
        if (area.Length > 0) { conds.Add("AREA = @p" + args.Count); args.Add(area); }
        if (pu.Length > 0) { conds.Add("PROCESSUNIT LIKE @p" + args.Count + " + '%'"); args.Add(pu); }
        string where = conds.Count > 0 ? " WHERE " + string.Join(" AND ", conds) : "";

        string sql = "SELECT TOP " + top + " * FROM " + ChartTable + " WITH (NOLOCK)"
                     + where + " ORDER BY UPDATE_TIME DESC";
        var rows = QueryRows(sql, args.ToArray());

        foreach (var row in rows)
        {
            var keys = new List<string>(row.Keys);
            foreach (var k in keys)
                if (row[k] is DateTime) row[k] = ((DateTime)row[k]).ToString("yyyy-MM-dd HH:mm:ss");
        }

        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Response.Write(ser.Serialize(new Dictionary<string, object> {
            { "ok", true }, { "count", rows.Count }, { "rows", rows }
        }));
    }

    // NON-ADDER profile single image (contour RAW). See TF2 page for details.
    private void HandleProfileImg()
    {
        string site = Regex.Replace(Request.QueryString["site"] ?? "12AP14", "[^0-9A-Za-z]", "");
        if (!string.Equals(site, "12AP14", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(site, "12AP14", StringComparison.OrdinalIgnoreCase)) site = "12AP14";
        string chartId = Regex.Replace(Request.QueryString["chartId"] ?? "", "[^0-9]", "");
        string chartSeq = Regex.Replace(Request.QueryString["chartSeq"] ?? "", "[^0-9]", "");
        string pointValue = Regex.Replace(Request.QueryString["pointValue"] ?? "", "[^0-9.]", "");
        string wafer = (Request.QueryString["wafer"] ?? "").Trim();

        var ser = new JavaScriptSerializer();
        if (chartId.Length == 0 || chartSeq.Length == 0)
        {
            Response.Write(ser.Serialize(new Dictionary<string, object> { { "ok", false }, { "error", "chartId/chartSeq required" } }));
            return;
        }

        string entryUrl = "http://10.10.101.170/Project1/_Contour_Multi.asp?site=" + Uri.EscapeDataString(site)
            + "&ChartID=" + Uri.EscapeDataString(chartId)
            + "&ChartSEQ=" + Uri.EscapeDataString(chartSeq)
            + (pointValue.Length > 0 ? "&PointValue=" + Uri.EscapeDataString(pointValue) : "");

        string html = HttpGetText(entryUrl);
        string imgUrl = ExtractRawImg(html, wafer);
        string usedUrl = entryUrl;

        if (imgUrl == null && !string.IsNullOrEmpty(html))
        {
            var dm = Regex.Match(html, @"_Contour_Multi_DataShowMap\.asp\?[^""'<>\s]+", RegexOptions.IgnoreCase);
            if (dm.Success)
            {
                string dmUrl = HttpUtility.HtmlDecode(dm.Value).Replace("&amp;", "&");
                if (!dmUrl.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                    dmUrl = "http://10.10.101.170/Project1/" + dmUrl.TrimStart('/');
                string dmHtml = HttpGetText(dmUrl);
                imgUrl = ExtractRawImg(dmHtml, wafer);
                usedUrl = dmUrl;
            }
        }

        Response.Write(ser.Serialize(new Dictionary<string, object> {
            { "ok", true }, { "imgUrl", imgUrl }, { "wafer", wafer }, { "url", usedUrl }
        }));
    }

    private static string ExtractRawImg(string html, string wafer)
    {
        if (string.IsNullOrEmpty(html)) return null;
        var matches = Regex.Matches(html, @"<img[^>]+src\s*=\s*['""]([^'""]+)['""]", RegexOptions.IgnoreCase);
        string firstRaw = null;
        foreach (Match mm in matches)
        {
            string src = HttpUtility.HtmlDecode(mm.Groups[1].Value);
            if (src.IndexOf("RAW", StringComparison.OrdinalIgnoreCase) < 0) continue;
            string abs = AbsUrl(src);
            if (firstRaw == null) firstRaw = abs;
            if (!string.IsNullOrEmpty(wafer) && abs.IndexOf(wafer, StringComparison.OrdinalIgnoreCase) >= 0) return abs;
        }
        return firstRaw;
    }

    private static string AbsUrl(string src)
    {
        if (src.StartsWith("http", StringComparison.OrdinalIgnoreCase)) return src;
        if (src.StartsWith("/")) return "http://10.10.101.170" + src;
        return "http://10.10.101.170/Project1/" + src.TrimStart('~').TrimStart('/');
    }

    private static string HttpGetText(string url)
    {
        var req = (HttpWebRequest)WebRequest.Create(url);
        req.Method = "GET";
        req.UserAgent = "Mozilla/5.0";
        req.Timeout = 15000;
        req.ReadWriteTimeout = 15000;
        req.AllowAutoRedirect = true;
        req.UseDefaultCredentials = true;
        req.Credentials = CredentialCache.DefaultCredentials;
        using (var resp = (HttpWebResponse)req.GetResponse())
        using (var stream = resp.GetResponseStream())
        {
            if (stream == null) return null;
            using (var sr = new StreamReader(stream, Encoding.UTF8))
                return sr.ReadToEnd();
        }
    }

    private static string JsonEscape(string s)
    {
        if (s == null) return "";
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "");
    }

    private static string ConnStr()
    {
        ConnectionStringSettings cs = ConfigurationManager.ConnectionStrings["EMST"];
        if (cs != null && !string.IsNullOrWhiteSpace(cs.ConnectionString))
            return cs.ConnectionString;
        return "Server=UMCESIDB02;Database=GPTPoCDB;User ID=GPTPoCDBUser;Password=DB02.2026;TrustServerCertificate=True;";
    }

    private static List<Dictionary<string, object>> QueryRows(string sql, params object[] args)
    {
        var rows = new List<Dictionary<string, object>>();
        using (SqlConnection conn = new SqlConnection(ConnStr()))
        {
            conn.Open();
            using (SqlCommand cmd = conn.CreateCommand())
            {
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = sql;
                cmd.CommandTimeout = 120;
                if (args != null)
                    for (int i = 0; i < args.Length; i++)
                        cmd.Parameters.AddWithValue("@p" + i, args[i] ?? DBNull.Value);

                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        var row = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
                        for (int i = 0; i < rdr.FieldCount; i++)
                            row[rdr.GetName(i)] = rdr.IsDBNull(i) ? null : rdr.GetValue(i);
                        rows.Add(row);
                    }
                }
            }
        }
        return rows;
    }
}
