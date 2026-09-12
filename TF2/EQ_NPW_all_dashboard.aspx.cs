using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
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
//   GET  EQ_NPW_all_dashboard.aspx            -> renders the page (no auth required)
//   POST EQ_NPW_all_dashboard.aspx?op=chat    -> proxy to LLM
//   GET  EQ_NPW_all_dashboard.aspx?op=data    -> generic TF2_NPW_CHART query
//   GET  EQ_NPW_all_dashboard.aspx?op=alarm   -> raw rows for the weekly alarm report
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
        if (string.Equals(opStr, "port", StringComparison.OrdinalIgnoreCase))
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            try { HandlePort(); }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(ex.Message) + "\"}");
            }
            Response.End();
            return;
        }
        if (string.Equals(opStr, "ocapdetail", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(opStr, "wafercount", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(opStr, "emst", StringComparison.OrdinalIgnoreCase))
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            try
            {
                if (string.Equals(opStr, "ocapdetail", StringComparison.OrdinalIgnoreCase)) HandleOcapDetail();
                else if (string.Equals(opStr, "wafercount", StringComparison.OrdinalIgnoreCase)) HandleWaferCount();
                else HandleEmst();
            }
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
    //   - MONITOR_TYPE: all types included (shown as a column on the client)
    //   - Alarm: ALARM_COUNT >= 1 (decided on the client)
    // The SQL pre-filters only drop rows the client would discard anyway, so it
    // does not change results, it only shrinks the payload.
    private void HandleAlarm()
    {
        DateTime refDate;
        if (!DateTime.TryParse(Request.QueryString["date"], out refDate)) refDate = DateTime.Today;
        // week start = most recent Tuesday on or before refDate
        // Daily range: the report now covers the picked single day (was weekly).
        DateTime weekStart = refDate.Date;                  // picked day
        DateTime weekEndExcl = weekStart.AddDays(1);        // next day (exclusive)
        DateTime weekEnd = weekStart;                       // same day

        var days = new List<string>();
        days.Add(weekStart.ToString("yyyy-MM-dd"));

        string sql =
            "SELECT PROCESSUNIT, CONVERT(varchar(10), UPDATE_TIME, 23) AS UPDATE_TIME, " +
            "MONITOR_TYPE, CHART_TYPE, CHART_NAME, CHART_ID, CHART_SEQ, CHART_DESC, ALARM_COUNT, MEASUREPU, MEAN_VALUE, WAFER, PARAMETER, " +
            "LOT, RECIPE " +
            "FROM " + ChartTable + " WITH (NOLOCK) " +
            "WHERE UPDATE_TIME >= @p0 AND UPDATE_TIME < @p1 " +
            "AND ISNULL(CHART_DESC,'') <> 'Engineering' " +
            "AND CHART_TYPE IN ('C-C','XBAR') " +
            "AND (PROCESSUNIT LIKE 'NISACVD%' OR PROCESSUNIT LIKE 'SACVD%')";
        var rows = QueryRows(sql, weekStart, weekEndExcl);

        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Response.Write(ser.Serialize(new Dictionary<string, object> {
            { "ok", true },
            { "week", new Dictionary<string, object> {
                { "label", weekStart.ToString("yyyy-MM-dd") },
                { "start", weekStart.ToString("yyyy-MM-dd") },
                { "end", weekEnd.ToString("yyyy-MM-dd") },
                { "days", days }
            }},
            { "rows", rows }
        }));
    }

    // Port lookup for the weekly alarm rows. ?date=YYYY-MM-DD (same week rule as
    // HandleAlarm). Called by the client in the background AFTER the page has
    // rendered, so the slow cross-DB join never blocks the initial load.
    // Links [MESI_DB].[dbo].[ews_lothist] by LOT -> LOTID (trailing '_ADD'
    // stripped) and the NEAREST EWS record around the NPW row's LASTDATATMST
    // (measurement data timestamp), TOP 1 ordered by absolute time distance.
    // Direction differs per block: ADDER (C-C) only accepts records BEFORE
    // LASTDATATMST (the scan produced the data), while NON-ADDER (XBAR) accepts
    // either side within +/- 7 days -- its lots may pass EWS only after the
    // thickness measurement, so a strictly-preceding rule found nothing.
    // A same-day (or fixed N-hour) match was too wide -- one lot scanned
    // several times pulled in duplicate ports; nearest-single-record avoids
    // both the duplicates and an arbitrary cut-off.
    // The RECIPE LIKE PPID + '%' condition (RECIPE may carry an extra suffix)
    // applies to ADDER (C-C) rows only; NON-ADDER (XBAR) matches by LOTID +
    // time window alone, since its RECIPE naming does not line up with ews
    // PPIDs. Because the two block types can thus yield different port sets
    // for the same lot+day, each result row carries BLK ('A'/'N') and the
    // client keys its lookup by LOT+day+BLK. Perf notes:
    //   - TOP 1 + ORDER BY JPTIME DESC over an index on (LOTID, JPTIME) is a
    //     seek plus a single backward row, so the per-row APPLY stays cheap;
    //   - a 7-day floor on JPTIME bounds the backward search range (pure search
    //     bound, does not change the nearest-preceding semantics in practice);
    //   - the whole query still runs once per week load, in the background,
    //     and is kicked off only AFTER the main table has rendered.
    // Returns { ok, rows: [ { LOT, UPDATE_TIME, PORTID }, ... ] }; the client
    // groups PORTIDs per LOT+day and fills the Port column in place.
    private void HandlePort()
    {
        DateTime refDate;
        if (!DateTime.TryParse(Request.QueryString["date"], out refDate)) refDate = DateTime.Today;
        // Daily range: matches HandleAlarm (single picked day).
        DateTime weekStart = refDate.Date;
        DateTime weekEndExcl = weekStart.AddDays(1);

        string sql =
            "SELECT DISTINCT c.LOT, CONVERT(varchar(10), c.UPDATE_TIME, 23) AS UPDATE_TIME, lh.PORTID, " +
            "CASE WHEN c.CHART_TYPE = 'C-C' THEN 'A' ELSE 'N' END AS BLK " +
            "FROM " + ChartTable + " c WITH (NOLOCK) " +
            "CROSS APPLY (SELECT TOP 1 h.PORTID FROM [MESI_DB].[dbo].[ews_lothist] h WITH (NOLOCK) " +
            "WHERE h.LOTID = CASE WHEN RIGHT(c.LOT,4)='_ADD' THEN LEFT(c.LOT, LEN(c.LOT)-4) ELSE c.LOT END " +
            "AND (c.CHART_TYPE = 'XBAR' OR c.RECIPE LIKE h.PPID + '%') " +
            "AND h.JPTIME >= DATEADD(day, -7, c.LASTDATATMST) " +
            "AND h.JPTIME <= CASE WHEN c.CHART_TYPE = 'C-C' THEN c.LASTDATATMST ELSE DATEADD(day, 7, c.LASTDATATMST) END " +
            "AND h.PORTID IS NOT NULL " +
            "ORDER BY ABS(DATEDIFF(second, h.JPTIME, c.LASTDATATMST))) lh " +
            "WHERE c.UPDATE_TIME >= @p0 AND c.UPDATE_TIME < @p1 " +
            "AND (c.ALARM_COUNT >= 1 OR c.MONITOR_TYPE = 'DOWN') AND c.LOT IS NOT NULL AND c.LASTDATATMST IS NOT NULL " +
            "AND (c.CHART_TYPE = 'XBAR' OR c.RECIPE IS NOT NULL) " +
            "AND ISNULL(c.CHART_DESC,'') <> 'Engineering' " +
            "AND c.CHART_TYPE IN ('C-C','XBAR') " +
            "AND (c.PROCESSUNIT LIKE 'NISACVD%' OR c.PROCESSUNIT LIKE 'SACVD%')";
        var rows = QueryRows(sql, weekStart, weekEndExcl);

        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Response.Write(ser.Serialize(new Dictionary<string, object> {
            { "ok", true }, { "rows", rows }
        }));
    }

    // ===== EMST detail popup (ported from OCAP.aspx, self-contained) =====
    //
    //   GET  ?op=ocapdetail&uchart_id=..&chart_seq=..
    //        OCAP record (NPW_OCAP_P56) joined with the chart row. Unlike
    //        OCAP.aspx this does NOT fail when there is no OCAP record: the chart
    //        row alone is returned with ocapFound=false so the EMST form still
    //        works for every alarm in the table.
    //   GET  ?op=wafercount&tool=SACVD-B06C&scope=CHAMBER|MF
    //        PM wafer count vs SPEC (same rules as OCAP / wafer_count site).
    //   GET  ?op=emst&uchart_id=..&chart_seq=..&date=YYYY-MM-DD -> { ok, exists, note, file }
    //   POST ?op=emst&uchart_id=..&chart_seq=..&date=YYYY-MM-DD body JSON -> { ok, note, file }
    //        All alarms of one day share one JSON file in emst_data/ next to
    //        this page: "YYYY-MM-DD EMST.json" = { date, notes: { "uid_seq": {...} } }.
    //        date = alarm date shown on the dashboard (defaults to today).
    //        A legacy per-alarm file "uid_seq.json" is still read as fallback.
    //        (Folder hidden from direct download by web.config hiddenSegments.)
    private const string OcapTable = "[GPTDB_USPC].[dbo].[NPW_OCAP_P56]";
    private const string UsageMeterTable = "[GPTDB_EAS].[dbo].[XSITEUSAGEMETER_P56]";
    private const string MeterTargetTable = "[GPTPoCDB].[dbo].[_MeterTarget_DB09]";
    private const string EmstFolder = "emst_data";
    private const int EmstMaxText = 4000;
    private static readonly object _emstLock = new object();

    private static string DigitsOnly(string v)
    {
        if (v == null) return "";
        string s = Regex.Replace(v, "[^0-9]", "");
        return s.Length > 20 ? s.Substring(0, 20) : s;
    }

    private static string TextField(Dictionary<string, object> src, string key, int maxLength)
    {
        object v;
        if (src == null || !src.TryGetValue(key, out v) || v == null) return "";
        string s = Convert.ToString(v).Trim();
        return s.Length > maxLength ? s.Substring(0, maxLength) : s;
    }

    private void HandleOcapDetail()
    {
        string uid = DigitsOnly(Request.QueryString["uchart_id"]);
        string seq = DigitsOnly(Request.QueryString["chart_seq"]);
        if (uid.Length == 0 || seq.Length == 0)
        {
            Response.StatusCode = 400;
            Response.Write("{\"ok\":false,\"error\":\"uchart_id and chart_seq are required\"}");
            return;
        }

        // Times are converted to text in SQL so the JSON is human readable
        // (JavaScriptSerializer would otherwise emit \/Date(...)\/).
        string ocapSql =
            "SELECT TOP (1) o.UCHART_ID, o.CHART_SEQ, o.CHART_NAME, o.STATUS, " +
            "CONVERT(varchar(19), o.CREATE_TIME, 120) AS CREATE_TIME, o.OWNERDEPT, o.PROCESSINGUNIT, " +
            "o.PARAMETER, o.RECIPE, o.LOT, o.MEAS_EQUIPMENT, o.CHART_OWNER, o.X_VIOLATED_RULE, " +
            "o.HOLD_LOT_FLAG, o.HOLD_EQ_FLAG, o.CONTAINMENT_ACTION, o.CORRECTIVE_ACTION, o.ROOT_CAUSE, " +
            "c.PROCESSUNIT, c.CHART_TYPE, c.MONITOR_TYPE, c.MEAN_VALUE, c.WAFER, c.MEASUREPU, " +
            "CONVERT(varchar(19), c.UPDATE_TIME, 120) AS NPW_UPDATE_TIME, " +
            "CONVERT(varchar(19), c.LASTDATATMST, 120) AS LASTDATATMST " +
            "FROM " + OcapTable + " o WITH (NOLOCK) " +
            "LEFT JOIN " + ChartTable + " c WITH (NOLOCK) ON c.CHART_ID = o.UCHART_ID AND c.CHART_SEQ = o.CHART_SEQ " +
            "WHERE o.UCHART_ID = @p0 AND o.CHART_SEQ = @p1 " +
            "ORDER BY o.CREATE_TIME DESC";
        var rows = QueryRows(ocapSql, uid, seq);
        bool found = rows.Count > 0;
        if (!found)
        {
            string chartSql =
                "SELECT TOP (1) CHART_ID AS UCHART_ID, CHART_SEQ, CHART_NAME, PROCESSUNIT, PROCESSUNIT AS PROCESSINGUNIT, " +
                "CHART_TYPE, MONITOR_TYPE, MEAN_VALUE, WAFER, MEASUREPU, LOT, RECIPE, PARAMETER, " +
                "CONVERT(varchar(19), UPDATE_TIME, 120) AS NPW_UPDATE_TIME, " +
                "CONVERT(varchar(19), LASTDATATMST, 120) AS LASTDATATMST " +
                "FROM " + ChartTable + " WITH (NOLOCK) WHERE CHART_ID = @p0 AND CHART_SEQ = @p1";
            rows = QueryRows(chartSql, uid, seq);
        }

        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Response.Write(ser.Serialize(new Dictionary<string, object> {
            { "ok", true }, { "ocapFound", found }, { "row", rows.Count > 0 ? rows[0] : null }
        }));
    }

    // Meter types that count for each tool (same rules as the wafer_count site):
    //   non-NISACVD: chamber -> WET_CLEAN, main frame -> BUFFER_WET_CLEAN
    //   NISACVD    : MF of B06/B07/B08 -> BUFFER_WET_CLEAN, other MF -> BUFFER-PM;
    //                chamber of B01 -> A-PM/B-PM, other chambers -> A-PM/WET_CLEAN
    private static string[] AllowedMeters(string entity, string mom, bool isMf)
    {
        if (entity != "NISACVD")
            return isMf ? new string[] { "BUFFER_WET_CLEAN" } : new string[] { "WET_CLEAN" };
        if (isMf)
            return (mom == "NISACVD-B06" || mom == "NISACVD-B07" || mom == "NISACVD-B08")
                ? new string[] { "BUFFER_WET_CLEAN" }
                : new string[] { "BUFFER-PM" };
        return mom == "NISACVD-B01"
            ? new string[] { "A-PM", "B-PM" }
            : new string[] { "A-PM", "WET_CLEAN" };
    }

    private void HandleWaferCount()
    {
        string tool = (Request.QueryString["tool"] ?? "").Trim();
        if (tool.Length > 40) tool = tool.Substring(0, 40);
        string scope = (Request.QueryString["scope"] ?? "").Trim();
        bool mfOnly = string.Equals(scope, "MF", StringComparison.OrdinalIgnoreCase);
        string toolUp = tool.ToUpperInvariant();

        string entity, mom, letters;
        Match m = Regex.Match(toolUp, @"^([A-Z0-9]+)-([A-Z])(\d{1,2})\s*([A-Z]*)");
        if (m.Success)
        {
            entity = m.Groups[1].Value;
            mom = entity + "-" + m.Groups[2].Value + m.Groups[3].Value.PadLeft(2, '0');
            letters = m.Groups[4].Value;
        }
        else
        {
            entity = toolUp; mom = toolUp; letters = "";
        }

        // No chamber letter means the main frame itself -> treat as MF.
        bool noSuffixAsMf = !mfOnly && letters.Length == 0;
        if (noSuffixAsMf) mfOnly = true;

        var eqpids = new List<string>();
        var chambers = new List<string>();
        if (mfOnly) eqpids.Add(mom);
        else
            foreach (char ch in letters)
            {
                string e = mom + ch;
                if (!eqpids.Contains(e)) { eqpids.Add(e); chambers.Add(e); }
            }

        var ph = new List<string>();
        for (int i = 0; i < eqpids.Count; i++) ph.Add("@p" + i);

        string sql =
            "SELECT x.EQPID, x.METERTYPE, x.DATA_VAL, sp.SPEC_VAL " +
            "FROM " + UsageMeterTable + " x " +
            "OUTER APPLY (SELECT TOP (1) t.ALARM AS SPEC_VAL FROM " + MeterTargetTable + " t " +
            "WHERE t.EQCH = x.EQPID AND t.METERTYPE = x.METERTYPE ORDER BY t.LASTREADINGTIME DESC) sp " +
            "WHERE x.EQPID IN (" + string.Join(", ", ph.ToArray()) + ") " +
            "ORDER BY x.EQPID, x.METERTYPE";
        var raw = QueryRows(sql, eqpids.ToArray());

        var rows = new List<object>();
        foreach (var r in raw)
        {
            string eqpid = Convert.ToString(r["EQPID"] ?? "").Trim().ToUpperInvariant();
            string meter = Convert.ToString(r["METERTYPE"] ?? "").Trim().ToUpperInvariant();
            bool isMf = eqpid == mom;
            if (Array.IndexOf(AllowedMeters(entity, mom, isMf), meter) < 0) continue;
            string dispMeter = (entity == "NISACVD" && meter == "WET_CLEAN") ? "B-PM" : meter;
            rows.Add(new Dictionary<string, object> {
                { "EQPID", eqpid },
                { "DISP_EQPID", isMf ? eqpid + "-MF" : eqpid },
                { "METERTYPE", meter },
                { "DISP_METERTYPE", dispMeter },
                { "DATA_VAL", r["DATA_VAL"] },
                { "SPEC_VAL", r["SPEC_VAL"] },
                { "ISMF", isMf }
            });
        }

        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        Response.Write(ser.Serialize(new Dictionary<string, object> {
            { "ok", true }, { "tool", tool }, { "scope", mfOnly ? "MF" : "CHAMBER" }, { "supported", true },
            { "entity", entity }, { "mom", mom }, { "chambers", chambers },
            { "noSuffixAsMf", noSuffixAsMf }, { "rows", rows }
        }));
    }

    private static Dictionary<string, object> EmstReadJson(string path)
    {
        if (!File.Exists(path)) return null;
        string json = File.ReadAllText(path, Encoding.UTF8);
        if (string.IsNullOrEmpty(json)) return null;
        try { return new JavaScriptSerializer { MaxJsonLength = int.MaxValue }.Deserialize<Dictionary<string, object>>(json); }
        catch { return null; }
    }

    // Daily file content: { date, notes: { "uid_seq": note } }. Returns the notes map (never null).
    private static Dictionary<string, object> EmstReadDayNotes(string path)
    {
        Dictionary<string, object> day = EmstReadJson(path);
        object n;
        Dictionary<string, object> notes = (day != null && day.TryGetValue("notes", out n)) ? n as Dictionary<string, object> : null;
        return notes ?? new Dictionary<string, object>();
    }

    // ?date=YYYY-MM-DD (alarm date on the dashboard); anything else -> today.
    private static string EmstDateKey(string v)
    {
        DateTime d;
        if (v != null && Regex.IsMatch(v.Trim(), "^[0-9]{4}-[0-9]{2}-[0-9]{2}$") &&
            DateTime.TryParseExact(v.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out d))
            return d.ToString("yyyy-MM-dd");
        return DateTime.Now.ToString("yyyy-MM-dd");
    }

    private void HandleEmst()
    {
        string uid = DigitsOnly(Request.QueryString["uchart_id"]);
        string seq = DigitsOnly(Request.QueryString["chart_seq"]);
        if (uid.Length == 0 || seq.Length == 0)
        {
            Response.StatusCode = 400;
            Response.Write("{\"ok\":false,\"error\":\"uchart_id and chart_seq are required\"}");
            return;
        }
        string dateKey = EmstDateKey(Request.QueryString["date"]);
        string folder = Server.MapPath(EmstFolder);
        // Names are built only from validated digits / a validated date (no path traversal possible).
        string fileName = dateKey + " EMST.json";
        string path = Path.Combine(folder, fileName);
        string legacyPath = Path.Combine(folder, uid + "_" + seq + ".json");
        string key = uid + "_" + seq;
        var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };

        if (!string.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase))
        {
            object found;
            Dictionary<string, object> note = EmstReadDayNotes(path).TryGetValue(key, out found) ? found as Dictionary<string, object> : null;
            if (note == null) note = EmstReadJson(legacyPath);   // saved before the daily-file layout
            Response.Write(ser.Serialize(new Dictionary<string, object> {
                { "ok", true }, { "exists", note != null }, { "note", note }, { "file", fileName }
            }));
            return;
        }

        string body;
        using (var sr = new StreamReader(Request.InputStream, Encoding.UTF8)) body = sr.ReadToEnd();
        Dictionary<string, object> incoming;
        try { incoming = string.IsNullOrEmpty(body) ? new Dictionary<string, object>() : (ser.Deserialize<Dictionary<string, object>>(body) ?? new Dictionary<string, object>()); }
        catch { incoming = new Dictionary<string, object>(); }
        string now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

        lock (_emstLock)
        {
            Directory.CreateDirectory(folder);
            Dictionary<string, object> notes = EmstReadDayNotes(path);
            object prev;
            Dictionary<string, object> existing = notes.TryGetValue(key, out prev) ? prev as Dictionary<string, object> : null;
            if (existing == null) existing = EmstReadJson(legacyPath);

            var note = new Dictionary<string, object>();
            note["uchart_id"] = uid;
            note["chart_seq"] = seq;
            note["date"] = dateKey;
            note["chart_name"] = TextField(incoming, "chart_name", 300);
            note["block"] = TextField(incoming, "block", 10);
            note["tool"] = TextField(incoming, "tool", 100);
            note["waferCount"] = TextField(incoming, "waferCount", 500);
            note["action"] = TextField(incoming, "action", EmstMaxText);
            note["followUp"] = TextField(incoming, "followUp", EmstMaxText);
            note["createdAt"] = (existing != null && existing.ContainsKey("createdAt")) ? existing["createdAt"] : now;
            note["updatedAt"] = now;
            notes[key] = note;

            var day = new Dictionary<string, object>();
            day["date"] = dateKey;
            day["updatedAt"] = now;
            day["notes"] = notes;

            // Write to a temp file then rename so a reader never sees a half file.
            string tmp = path + ".tmp";
            File.WriteAllText(tmp, ser.Serialize(day), new UTF8Encoding(false));
            if (File.Exists(path)) File.Delete(path);
            File.Move(tmp, path);

            Response.Write(ser.Serialize(new Dictionary<string, object> { { "ok", true }, { "note", note }, { "file", fileName } }));
        }
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
