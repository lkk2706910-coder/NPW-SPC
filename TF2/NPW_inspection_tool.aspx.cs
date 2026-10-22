using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;

// NPW inspection tool (PCRB-style check) on top of TF2_NPW_CHART.
// Same shape as the NPW alarm control page: one .aspx renders the UI, the
// code-behind answers ?op= JSON requests and ends the response.
//
// Routes:
//   GET  NPW_inspection_tool.aspx                 -> renders the page
//   GET  NPW_inspection_tool.aspx?op=search       -> one row per chart in the range:
//          &start=YYYY-MM-DDTHH:mm &end=YYYY-MM-DDTHH:mm (UPDATE_TIME; end inclusive to the minute;
//          a date-only value means 00:00 for start / 23:59 for end)
//          &cid=<CHART_ID exact> &cname=<CHART_NAME contains> &pu=<PROCESSUNIT contains>
//          &prod=ctrl|ocap   PROD Type: ctrl = all MONITOR_TYPE (default), ocap = NORMAL / PM only
//          returns { ok, rows:[{CHART_ID, CHART_NAME, PROCESSUNIT, CHART_TYPE, N, AVG, STDEV,
//                               MIN, MAX, FIRST_TIME, LAST_TIME}], truncated }
//          N / AVG / STDEV are over MEAN_VALUE of the matching rows; STDEV is the
//          sample standard deviation (same as Excel STDEV.S / STDEVA on numbers).
//          With &cid= only, this is also the per-chart stats call used to fill
//          the BSL / wafer extend rows of the check table for two ranges.
//   GET  NPW_inspection_tool.aspx?op=values&cid=&start=&end=  -> the individual points
//          { ok, rows:[{d, seq, mean, lot, wafer, pu, ucl, lcl, xbar, spech, specl}] }
//
// The range filters on UPDATE_TIME (datetime); start/end are sent to the minute.
//
// NOTE: keep this file pure ASCII. Some servers compile .cs as Big5/CP950,
// which can eat the newline after a non-ASCII char and break compilation.
public partial class NPW_Inspection : Page
{
    private const string DateExpr = "UPDATE_TIME";

    // TF1 page name -> TF1 table, otherwise TF2 (same rule as the alarm page).
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

    private const int MaxCharts = 400;
    private const int MaxPoints = 5000;

    protected void Page_Load(object sender, EventArgs e)
    {
        string opStr = Request.QueryString["op"];
        if (string.IsNullOrEmpty(opStr)) return;   // plain page render

        Response.ContentType = "application/json; charset=utf-8";
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        try
        {
            if (string.Equals(opStr, "search", StringComparison.OrdinalIgnoreCase)) HandleSearch();
            else if (string.Equals(opStr, "values", StringComparison.OrdinalIgnoreCase)) HandleValues();
            else
            {
                Response.StatusCode = 400;
                Response.Write("{\"ok\":false,\"error\":\"unknown op\"}");
            }
        }
        catch (Exception ex)
        {
            Response.StatusCode = 500;
            Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(ex.Message) + "\"}");
        }
        Response.End();
    }

    // ---- PROD Type: ?prod=ctrl (default, all MONITOR_TYPE) | ocap (NORMAL / PM only) ----
    private string ProdTypeFilter()
    {
        string prod = (Request.QueryString["prod"] ?? "").Trim();
        if (string.Equals(prod, "ocap", StringComparison.OrdinalIgnoreCase))
            return " AND UPPER(MONITOR_TYPE) IN ('NORMAL','PM')";
        return "";
    }

    // ---- time range to the minute: start inclusive, end inclusive (converted to < end+1min) ----
    // Accepts "yyyy-MM-ddTHH:mm", "yyyy-MM-dd HH:mm", "yyyy-MM-ddTHH:mm:ss" or a bare date
    // (start -> 00:00, end -> 23:59).
    private static readonly string[] RangeFormats = { "yyyy-MM-ddTHH:mm", "yyyy-MM-dd HH:mm", "yyyy-MM-ddTHH:mm:ss", "yyyy-MM-dd HH:mm:ss" };
    private static bool TryParseStamp(string v, bool isEnd, out DateTime d)
    {
        v = (v ?? "").Trim();
        if (DateTime.TryParseExact(v, RangeFormats, CultureInfo.InvariantCulture, DateTimeStyles.None, out d)) return true;
        if (DateTime.TryParseExact(v, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out d))
        {
            if (isEnd) d = d.Date.AddDays(1).AddMinutes(-1);
            return true;
        }
        return false;
    }

    private bool ReadRange(out DateTime start, out DateTime endExcl, out string error)
    {
        error = null;
        DateTime s, e;
        bool okS = TryParseStamp(Request.QueryString["start"], false, out s);
        bool okE = TryParseStamp(Request.QueryString["end"], true, out e);
        if (!okE) e = DateTime.Now;
        if (!okS) s = e.Date.AddDays(-30);
        s = new DateTime(s.Year, s.Month, s.Day, s.Hour, s.Minute, 0);
        e = new DateTime(e.Year, e.Month, e.Day, e.Hour, e.Minute, 0);
        if (s > e) { DateTime t = s; s = e; e = t; }
        if ((e - s).TotalDays > 400) { error = "time range too long (max 400 days)"; start = s; endExcl = e; return false; }
        start = s;
        endExcl = e.AddMinutes(1);
        return true;
    }

    private void HandleSearch()
    {
        DateTime start, endExcl; string err;
        if (!ReadRange(out start, out endExcl, out err))
        {
            Response.StatusCode = 400;
            Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(err) + "\"}");
            return;
        }
        string cid = Regex.Replace(Request.QueryString["cid"] ?? "", "[^0-9]", "");
        string cname = (Request.QueryString["cname"] ?? "").Trim();
        string pu = (Request.QueryString["pu"] ?? "").Trim();
        if (cname.Length > 200) cname = cname.Substring(0, 200);
        if (pu.Length > 100) pu = pu.Substring(0, 100);

        var args = new List<object>();
        var where = new StringBuilder();
        where.Append("WHERE " + DateExpr + " >= @p" + args.Count); args.Add(start);
        where.Append(" AND " + DateExpr + " < @p" + args.Count); args.Add(endExcl);
        where.Append(" AND MEAN_VALUE IS NOT NULL");
        where.Append(ProdTypeFilter());
        if (cid.Length > 0) { where.Append(" AND CHART_ID = @p" + args.Count); args.Add(cid); }
        if (cname.Length > 0) { where.Append(" AND CHART_NAME LIKE @p" + args.Count); args.Add(LikePattern(cname)); }
        if (pu.Length > 0) { where.Append(" AND PROCESSUNIT LIKE @p" + args.Count); args.Add(LikePattern(pu)); }

        // One row per chart: count / mean / sample stdev of MEAN_VALUE in the range.
        string sql =
            "SELECT TOP " + (MaxCharts + 1) + " CHART_ID, CHART_NAME, PROCESSUNIT, MAX(CHART_TYPE) AS CHART_TYPE, " +
            "COUNT(MEAN_VALUE) AS N, " +
            "AVG(CAST(MEAN_VALUE AS float)) AS AVG_VAL, " +
            "STDEV(CAST(MEAN_VALUE AS float)) AS SD_VAL, " +
            "MIN(CAST(MEAN_VALUE AS float)) AS MIN_VAL, MAX(CAST(MEAN_VALUE AS float)) AS MAX_VAL, " +
            "CONVERT(varchar(19), MIN(" + DateExpr + "), 120) AS FIRST_TIME, " +
            "CONVERT(varchar(19), MAX(" + DateExpr + "), 120) AS LAST_TIME " +
            "FROM " + ChartTable + " WITH (NOLOCK) " +
            where.ToString() + " " +
            "GROUP BY CHART_ID, CHART_NAME, PROCESSUNIT " +
            "ORDER BY PROCESSUNIT, CHART_NAME, CHART_ID";
        var rows = QueryRows(sql, args.ToArray());

        bool truncated = rows.Count > MaxCharts;
        if (truncated) rows.RemoveAt(rows.Count - 1);

        var outRows = new List<object>();
        foreach (var r in rows)
        {
            outRows.Add(new Dictionary<string, object> {
                { "CHART_ID", Convert.ToString(r["CHART_ID"]) },
                { "CHART_NAME", r["CHART_NAME"] },
                { "PROCESSUNIT", r["PROCESSUNIT"] },
                { "CHART_TYPE", r["CHART_TYPE"] },
                { "N", r["N"] },
                { "AVG", r["AVG_VAL"] },
                { "STDEV", r["SD_VAL"] },
                { "MIN", r["MIN_VAL"] },
                { "MAX", r["MAX_VAL"] },
                { "FIRST_TIME", r["FIRST_TIME"] },
                { "LAST_TIME", r["LAST_TIME"] }
            });
        }
        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Response.Write(ser.Serialize(new Dictionary<string, object> {
            { "ok", true }, { "rows", outRows }, { "truncated", truncated },
            { "start", start.ToString("yyyy-MM-dd HH:mm") }, { "end", endExcl.AddMinutes(-1).ToString("yyyy-MM-dd HH:mm") }
        }));
    }

    private void HandleValues()
    {
        DateTime start, endExcl; string err;
        if (!ReadRange(out start, out endExcl, out err))
        {
            Response.StatusCode = 400;
            Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(err) + "\"}");
            return;
        }
        string cid = Regex.Replace(Request.QueryString["cid"] ?? "", "[^0-9]", "");
        if (cid.Length == 0)
        {
            Response.StatusCode = 400;
            Response.Write("{\"ok\":false,\"error\":\"cid required\"}");
            return;
        }
        string sql =
            "SELECT TOP " + MaxPoints + " CHART_SEQ, CONVERT(varchar(19), UPDATE_TIME, 120) AS D, " +
            "CAST(MEAN_VALUE AS float) AS MEAN_VALUE, LOT, WAFER, PROCESSUNIT, UCL, LCL, XBAR, SPEC_HIGH, SPEC_LOW " +
            "FROM " + ChartTable + " WITH (NOLOCK) " +
            "WHERE CHART_ID = @p0 AND " + DateExpr + " >= @p1 AND " + DateExpr + " < @p2 AND MEAN_VALUE IS NOT NULL " +
            ProdTypeFilter() + " " +
            "ORDER BY " + DateExpr + ", CHART_SEQ";
        var rows = QueryRows(sql, cid, start, endExcl);
        var outRows = new List<object>();
        foreach (var r in rows)
        {
            outRows.Add(new Dictionary<string, object> {
                { "d", r["D"] }, { "seq", r["CHART_SEQ"] }, { "mean", r["MEAN_VALUE"] },
                { "lot", r["LOT"] }, { "wafer", r["WAFER"] }, { "pu", r["PROCESSUNIT"] },
                { "ucl", r["UCL"] }, { "lcl", r["LCL"] }, { "xbar", r["XBAR"] },
                { "spech", r["SPEC_HIGH"] }, { "specl", r["SPEC_LOW"] }
            });
        }
        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Response.Write(ser.Serialize(new Dictionary<string, object> { { "ok", true }, { "rows", outRows } }));
    }

    // User text -> LIKE pattern. '%' typed by the user is kept as a wildcard
    // (and the text is then used as-is, e.g. "SACVD-B1%" or "%5.5K%PA%");
    // without any '%' the text is matched as "contains". '_' and '[' are
    // always literal because chart names contain them (HTSIN130_11 ...).
    private static string LikePattern(string s)
    {
        string esc = s.Replace("[", "[[]").Replace("_", "[_]");
        return esc.IndexOf('%') >= 0 ? esc : "%" + esc + "%";
    }


    private static string JsonEscape(string s)
    {
        if (s == null) return "";
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "");
    }

    // ---- Inlined DB helper (self-contained, no App_Code dependency) ----
    private static string ConnStr()
    {
        ConnectionStringSettings cs = ConfigurationManager.ConnectionStrings["EMST"];
        if (cs != null && !string.IsNullOrWhiteSpace(cs.ConnectionString))
            return cs.ConnectionString;
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
