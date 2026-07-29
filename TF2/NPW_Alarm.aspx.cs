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

// No-auth home page + AI chat proxy + NPW weekly alarm data.
//
// Routes:
//   GET  NPW_Alarm.aspx            -> renders the page (no auth required)
//   POST NPW_Alarm.aspx?op=chat    -> proxy to LLM
//   GET  NPW_Alarm.aspx?op=data    -> generic TF2_NPW_CHART query
//   GET  NPW_Alarm.aspx?op=alarm   -> raw rows for the weekly alarm report
//
// NOTE: keep this file pure ASCII. Some servers compile .cs as Big5/CP950,
// which can eat the newline after a non-ASCII char and break compilation.
public partial class NPW_Alarm : Page
{
    // Source table: TF1 page -> TF1_NPW_CHART, otherwise TF2_NPW_CHART.
    // Decided by the requested page name so the same code serves both.
    protected string ChartTable
    {
        get
        {
            string p = (Request != null && Request.Path != null) ? Request.Path : "";
            return (p.IndexOf("TF1", StringComparison.OrdinalIgnoreCase) >= 0)
                ? "GPTDB_USPC.dbo.TF1_NPW_CHART"
                : "GPTDB_USPC.dbo.TF2_NPW_CHART";
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        string opStr = Request.QueryString["op"];
        if (string.Equals(opStr, "chat", StringComparison.OrdinalIgnoreCase))
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            try { HandleChat(); }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(ex.Message) + "\"}");
            }
            Response.End();
            return;
        }
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
        if (string.Equals(opStr, "getchecks", StringComparison.OrdinalIgnoreCase))
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            try { HandleGetChecks(); }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(ex.Message) + "\"}");
            }
            Response.End();
            return;
        }
        if (string.Equals(opStr, "savecheck", StringComparison.OrdinalIgnoreCase))
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            try { HandleSaveCheck(); }
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

    // Shared schedule checkbox state, stored in a JSON file next to this page
    // so all users see the same checks. File: sched_checks.json in the page folder.
    private static readonly object _schedLock = new object();
    private string SchedFile() { return Server.MapPath("sched_checks.json"); }

    private void HandleGetChecks()
    {
        string path = SchedFile();
        string json = "{}";
        lock (_schedLock)
        {
            if (File.Exists(path))
            {
                try { json = File.ReadAllText(path, Encoding.UTF8); }
                catch { json = "{}"; }
                if (string.IsNullOrWhiteSpace(json)) json = "{}";
            }
        }
        Response.Write("{\"ok\":true,\"checks\":" + json + "}");
    }

    private void HandleSaveCheck()
    {
        string body;
        using (var sr = new StreamReader(Request.InputStream, Encoding.UTF8)) body = sr.ReadToEnd();
        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Dictionary<string, object> req;
        try { req = ser.Deserialize<Dictionary<string, object>>(body) ?? new Dictionary<string, object>(); }
        catch { req = new Dictionary<string, object>(); }

        object ko, co, bo;
        req.TryGetValue("key", out ko);
        req.TryGetValue("checked", out co);
        req.TryGetValue("by", out bo);
        string key = ko == null ? null : Convert.ToString(ko);
        bool isChecked = co != null && (co is bool ? (bool)co : (Convert.ToString(co) == "true" || Convert.ToString(co) == "1"));
        string by = bo == null ? "" : Convert.ToString(bo).Trim();
        if (by.Length > 40) by = by.Substring(0, 40);
        if (string.IsNullOrEmpty(key))
        {
            Response.Write("{\"ok\":false,\"error\":\"key required\"}");
            return;
        }

        string path = SchedFile();
        string at = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        lock (_schedLock)
        {
            Dictionary<string, object> map;
            try
            {
                if (File.Exists(path))
                {
                    string t = File.ReadAllText(path, Encoding.UTF8);
                    map = string.IsNullOrWhiteSpace(t) ? new Dictionary<string, object>()
                        : (ser.Deserialize<Dictionary<string, object>>(t) ?? new Dictionary<string, object>());
                }
                else map = new Dictionary<string, object>();
            }
            catch { map = new Dictionary<string, object>(); }

            if (isChecked) map[key] = new Dictionary<string, object> { { "by", by }, { "at", at } };
            else map.Remove(key);
            File.WriteAllText(path, ser.Serialize(map), Encoding.UTF8);
        }
        Response.Write("{\"ok\":true,\"at\":\"" + at + "\"}");
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
    // week, defaults to today). The browser does the aggregation, mirroring the
    // original TF2_NPW.html tool. Rules:
    //   - week range: Tuesday..Monday (bucketed by UPDATE_TIME)
    //   - ADDER / NON-ADDER: CHART_TYPE 'C-C' / 'XBAR'
    //   - Entity: PROCESSUNIT prefix before '-' (only NISACVD / SACVD shown)
    //   - exclude Engineering: CHART_DESC <> 'Engineering'
    //   - MONITOR_TYPE: no longer filtered (all types included)
    //   - Alarm: ALARM_COUNT >= 1 (decided on the client)
    // The SQL pre-filters only drop rows the client would discard anyway, so it
    // does not change results, it only shrinks the payload.
    private void HandleAlarm()
    {
        DateTime refDate;
        if (!DateTime.TryParse(Request.QueryString["date"], out refDate)) refDate = DateTime.Today;
        // week start = most recent Tuesday on or before refDate
        int diff = (((int)refDate.DayOfWeek) - ((int)DayOfWeek.Tuesday) + 7) % 7;
        DateTime weekStart = refDate.Date.AddDays(-diff);   // Tuesday
        DateTime weekEndExcl = weekStart.AddDays(7);        // next Tuesday (exclusive)
        DateTime weekEnd = weekStart.AddDays(6);            // Monday

        var days = new List<string>();
        for (int i = 0; i < 7; i++) days.Add(weekStart.AddDays(i).ToString("yyyy-MM-dd"));

        // PORTID comes from [MESI_DB].[dbo].[ews_lothist] (same server), linked by
        // LOT -> LOTID, RECIPE -> PPID, and the alarm date -> JPTIME (same day).
        // NPW.RECIPE may carry an extra suffix (e.g. 'PPID_BS020'), so match
        // RECIPE LIKE PPID + '%'. NPW.LOT may carry a trailing '_ADD', which is
        // stripped before matching LOTID. The date match (CONVERT(date,JPTIME) =
        // alarm date) collapses the same lot's multiple measurements/steps over
        // time to the one measured that day, avoiding spurious multi-port results. The OUTER APPLY
        // aggregates ALL distinct matching PORTIDs into one comma-separated value
        // (FOR XML PATH), so a lot mapping to several ports shows all of them while
        // still keeping exactly one row per alarm record (no row multiplication ->
        // alarm counts stay correct). The client splits + de-dupes per chart.
        // Perf: the cross-DB lookup runs only for alarm rows (ALARM_COUNT >= 1,
        // LOT/RECIPE not null) -- a startup predicate so non-alarm rows skip the
        // ews_lothist scan entirely; PORTID is simply NULL for them.
        string sql =
            "SELECT c.PROCESSUNIT, CONVERT(varchar(10), c.UPDATE_TIME, 23) AS UPDATE_TIME, " +
            "c.MONITOR_TYPE, c.CHART_TYPE, c.CHART_NAME, c.CHART_ID, c.CHART_SEQ, c.CHART_DESC, c.ALARM_COUNT, c.MEASUREPU, c.MEAN_VALUE, c.WAFER, c.PARAMETER, " +
            "c.LOT, c.RECIPE, lh.PORTID " +
            "FROM " + ChartTable + " c WITH (NOLOCK) " +
            "OUTER APPLY (SELECT PORTID = STUFF((SELECT DISTINCT ', ' + CONVERT(varchar(50), h.PORTID) " +
            "FROM [MESI_DB].[dbo].[ews_lothist] h WITH (NOLOCK) " +
            "WHERE c.ALARM_COUNT >= 1 AND c.LOT IS NOT NULL AND c.RECIPE IS NOT NULL " +
            "AND h.LOTID = CASE WHEN RIGHT(c.LOT,4)='_ADD' THEN LEFT(c.LOT, LEN(c.LOT)-4) ELSE c.LOT END " +
            "AND c.RECIPE LIKE h.PPID + '%' " +
            "AND CONVERT(date, h.JPTIME) = CONVERT(date, c.UPDATE_TIME) " +
            "AND h.PORTID IS NOT NULL " +
            "FOR XML PATH(''), TYPE).value('.','nvarchar(max)'), 1, 2, '')) lh " +
            "WHERE c.UPDATE_TIME >= @p0 AND c.UPDATE_TIME < @p1 " +
            "AND ISNULL(c.CHART_DESC,'') <> 'Engineering' " +
            "AND c.CHART_TYPE IN ('C-C','XBAR') " +
            "AND (c.PROCESSUNIT LIKE 'NISACVD%' OR c.PROCESSUNIT LIKE 'SACVD%')";
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
    // Optional ?days=60 history window (default 60), bounded by ?end=YYYY-MM-DD.
    // Returns { ok, series: { CHART_ID: [ {d,xbar,ucl,lcl,mean,alarm,lot,wafer}, ... ] } }.
    private void HandleChartData()
    {
        string cidsRaw = (Request.QueryString["cids"] ?? "").Trim();
        if (cidsRaw.Length == 0)
        {
            Response.Write("{\"ok\":true,\"series\":{}}");
            return;
        }
        // sanitize + cap the id list
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
        end = end.Date.AddDays(1);                 // inclusive of end date
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

    // Generic read from GPTDB_USPC.dbo.TF2_NPW_CHART, returns JSON.
    // Optional query params: ?area=TF2  &pu=NISACVD  &top=200
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

        // DateTime -> string for the client (avoid /Date(ms)/).
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

    private void HandleChat()
    {
        string url = ConfigurationManager.AppSettings["AiGatewayUrl"];
        string apiKey = ConfigurationManager.AppSettings["AiApiKey"];
        string userId = ConfigurationManager.AppSettings["AiUserId"];
        string model = ConfigurationManager.AppSettings["AiModel"];
        string systemPrompt = ConfigurationManager.AppSettings["AiSystemPrompt"];
        if (string.IsNullOrEmpty(systemPrompt)) systemPrompt = "You are a helpful assistant.";
        if (string.IsNullOrEmpty(url) || string.IsNullOrEmpty(apiKey))
        {
            Response.StatusCode = 500;
            Response.Write("{\"ok\":false,\"error\":\"AiGatewayUrl / AiApiKey not configured\"}");
            return;
        }

        string body;
        using (var sr = new StreamReader(Request.InputStream, Encoding.UTF8)) body = sr.ReadToEnd();
        var ser = new JavaScriptSerializer { MaxJsonLength = 200 * 1024 * 1024 };
        Dictionary<string, object> req;
        try { req = ser.Deserialize<Dictionary<string, object>>(body) ?? new Dictionary<string, object>(); }
        catch
        {
            Response.StatusCode = 400;
            Response.Write("{\"ok\":false,\"error\":\"invalid json\"}");
            return;
        }

        var messages = new System.Collections.ArrayList();
        messages.Add(new Dictionary<string, object> { { "role", "system" }, { "content", systemPrompt } });
        object clientMessages;
        if (req.TryGetValue("messages", out clientMessages) && clientMessages is System.Collections.ArrayList)
        {
            foreach (var m in (System.Collections.ArrayList)clientMessages)
                if (m != null) messages.Add(m);
        }
        var payload = new Dictionary<string, object> { { "messages", messages } };
        // New gateway routes by the "model" field in the body (not by URL path).
        // Only include it when AiModel is configured; otherwise leave it off.
        if (!string.IsNullOrEmpty(model)) payload["model"] = model;
        byte[] payloadBytes = Encoding.UTF8.GetBytes(ser.Serialize(payload));

        // New gateway is HTTPS; older .NET Framework defaults do not enable
        // TLS 1.2, causing "Could not create SSL/TLS secure channel". Enable
        // TLS 1.2 (3072) and TLS 1.3 (12288) where supported.
        try { ServicePointManager.SecurityProtocol |= (SecurityProtocolType)3072; } catch { }
        try { ServicePointManager.SecurityProtocol |= (SecurityProtocolType)12288; } catch { }

        var hreq = (HttpWebRequest)WebRequest.Create(url);
        // New gateway sits behind Windows Integrated Authentication (Negotiate/
        // NTLM). Send the server's own Windows identity (app pool account) so the
        // gateway is satisfied server-to-server -- the browser never sees a 401
        // challenge, so no Windows login popup for the user.
        hreq.UseDefaultCredentials = true;
        hreq.PreAuthenticate = true;
        hreq.Method = "POST";
        hreq.Accept = "*/*";
        hreq.ContentType = "application/json";
        hreq.Headers["api-key"] = apiKey;
        if (!string.IsNullOrEmpty(userId)) hreq.Headers["user-id"] = userId;
        hreq.Timeout = 120000;
        hreq.ReadWriteTimeout = 120000;
        hreq.ContentLength = payloadBytes.Length;
        try
        {
            using (var s = hreq.GetRequestStream()) s.Write(payloadBytes, 0, payloadBytes.Length);
            using (var resp = (HttpWebResponse)hreq.GetResponse())
            using (var sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
                Response.Write(sr.ReadToEnd());
        }
        catch (WebException wex)
        {
            string detail = "";
            int status = 502;
            var http = wex.Response as HttpWebResponse;
            if (http != null)
            {
                status = (int)http.StatusCode;
                try
                {
                    using (var sr = new StreamReader(http.GetResponseStream(), Encoding.UTF8))
                        detail = sr.ReadToEnd();
                }
                catch { }
            }
            // Never relay a 401/407 to the browser: the app's IIS would attach a
            // WWW-Authenticate: Negotiate challenge and the browser would pop up a
            // Windows login dialog. Surface the failure as 502 instead; the real
            // status/detail still travels in the JSON body (front-end reads it).
            Response.StatusCode = (status == 401 || status == 407) ? 502 : status;
            Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(wex.Message) + "\",\"detail\":" + ser.Serialize(detail) + "}");
        }
    }

    // NON-ADDER profile single image. ?chartId=&chartSeq=&pointValue=&site=&wafer=
    // Mirrors the SpcMapProxy/.ashx technique but on the CONTOUR path: fetch the
    // contour entry page server-side (it builds myParaList itself, so we don't
    // need the parameter base), follow the DataShowMap page, and extract the RAW
    // wafer-map <img> (preferring the alarm point's WAFER). Returns { ok, imgUrl }.
    private void HandleProfileImg()
    {
        string site = Regex.Replace(Request.QueryString["site"] ?? "12AP58", "[^0-9A-Za-z]", "");
        if (!string.Equals(site, "12AP58", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(site, "12AP14", StringComparison.OrdinalIgnoreCase)) site = "12AP58";
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

        // Entry page may only reference the DataShowMap sub-page (with the
        // server-built myParaList). Follow it and extract there.
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

    // Find the RAW contour <img>; prefer the one whose URL contains the wafer.
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

    // GET a page server-side with Windows integrated auth (intranet pages).
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

    // ---- Inlined DB helper (self-contained, no App_Code dependency) ----
    // App_Code only auto-compiles at the application root. This page may be
    // dropped into a subfolder of an existing app, so the helper lives here.
    private static string ConnStr()
    {
        ConnectionStringSettings cs = ConfigurationManager.ConnectionStrings["EMST"];
        if (cs != null && !string.IsNullOrWhiteSpace(cs.ConnectionString))
            return cs.ConnectionString;
        // Fallback if the app's web.config has no EMST entry.
        return "Server=UMCESIDB02;Database=GPTPoCDB;User ID=GPTPoCDBUser;Password=DB02.2026;TrustServerCertificate=True;";
    }

    // Parameters map to @p0, @p1, ... in order.
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
