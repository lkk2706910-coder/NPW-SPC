using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;

// OCAP — 後端資料（code-behind）
//
// 運作方式：
//   帶 ?action=xxx  → 回傳 JSON（資料 API）
//   不帶參數        → 由 .aspx 標記渲染前端 HTML
//
// API：
//   ?action=ping                                  連線檢查
//   ?action=ocap&date=2026-09-10                  該日（依 CREATE_TIME）T_EQ1/2/3 三個 section 的 OCAP 資料
//   ?action=detail&uchart_id=85766&chart_seq=1832 單筆 OCAP + 對應 TF2_NPW_CHART 資料（MEAN_VALUE/WAFER/MEASUREPU…）
//   ?action=port&uchart_id=...&chart_seq=...      該筆 LOT 的 Port（跨庫 MESI_DB.ews_lothist，較慢，前端背景載入）
//   ?action=chartdata&cid=85766&end=2026-09-10    該 chart 近 N 天趨勢資料（Trend chart 用）
//   ?action=profileimg&uchart_id=..&chart_seq=..&pointValue=..&site=..&wafer=..
//                                                 NON-ADDER（CHART_NAME 含 U% / RANGE）的 Profile RAW 圖網址
//   ?action=wafercount&tool=SACVD-B06C&scope=CHAMBER|MF
//                                                 PM wafer count 與 SPEC（沿用 wafer_count 網站規則）
//                                                 scope=MF 只回母機台（RECIPE 含 XFER 時用），CHAMBER 只回 chamber
//
// PRE_Map / ADDER_Map / Measure_Tool 由 TF2api/SpcMapInfoProxy.ashx 代理 SPC 系統取得，
// 對角度（Wafer Match）由 WaferMatch.html 提供，皆沿用 NPW 網站的做法。
public partial class OCAP : Page
{
    // Web.config <connectionStrings> 裡的名稱
    private const string ConnectionStringName = "AppDb";

    private const int CommandTimeoutSeconds = 120;
    private const int MaxRows = 5000;

    // 資料來源
    private const string OcapTable      = "[GPTDB_USPC].[dbo].[NPW_OCAP_P56]";
    private const string NpwChartTable  = "[GPTDB_USPC].[dbo].[TF2_NPW_CHART]";
    private const string EwsLotHistTable = "[MESI_DB].[dbo].[ews_lothist]";

    // SPC 系統（Profile 圖頁面所在），走 Windows 整合驗證
    private const string SpcHost = "http://10.10.101.170";

    // Wafer count（沿用 wafer_count 網站）：使用量計數器與 SPEC 對照表
    private const string UsageMeterTable = "[GPTDB_EAS].[dbo].[XSITEUSAGEMETER_P56]";
    private const string MeterTargetTable = "[GPTPoCDB].[dbo].[_MeterTarget_DB09]";

    // 固定顯示的 section（OWNERDEPT），順序就是頁面上的排列順序；沒資料的 section 也會顯示空白區塊
    private static readonly string[] Sections = {
        "12A_FAB2/TF2/T_EQ1",
        "12A_FAB2/TF2/T_EQ2",
        "12A_FAB2/TF2/T_EQ3"
    };

    // 給 .aspx 用：把 Sections 序列化成 JSON，讓前端一載入就能畫出固定版面
    protected string SectionsJson
    {
        get { return new JavaScriptSerializer().Serialize(Sections); }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        string action = Clean(Request["action"], 30);

        // 沒有 action → 顯示前端 HTML，這裡不處理
        if (action.Length == 0) return;

        Response.Clear();
        Response.ContentType = "application/json; charset=utf-8";
        Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache);

        // 每個 action 都回 Dictionary，統一在這裡加上伺服器端耗時（elapsedMs），方便分辨是 DB 慢還是網路慢
        Stopwatch sw = Stopwatch.StartNew();
        try
        {
            Dictionary<string, object> result = null;
            switch (action.ToUpperInvariant())
            {
                case "PING":
                    result = Ping();
                    break;

                case "OCAP":
                    result = QueryOcapByDay(Clean(Request["date"], 10));
                    break;

                case "DETAIL":
                    result = QueryDetail(Digits(Request["uchart_id"]), Digits(Request["chart_seq"]));
                    break;

                case "PORT":
                    result = QueryPort(Digits(Request["uchart_id"]), Digits(Request["chart_seq"]));
                    break;

                case "CHARTDATA":
                    result = QueryChartData(Digits(Request["cid"]), Clean(Request["end"], 10), Clean(Request["days"], 3));
                    break;

                case "PROFILEIMG":
                    result = FetchProfileImg(
                        Digits(Request["uchart_id"]), Digits(Request["chart_seq"]),
                        Clean(Request["pointValue"], 30), Clean(Request["site"], 10), Clean(Request["wafer"], 30));
                    break;

                case "WAFERCOUNT":
                    result = QueryWaferCount(Clean(Request["tool"], 40), Clean(Request["scope"], 10));
                    break;
            }

            if (result == null)
            {
                WriteError("未知的 action：" + action, 400);
            }
            else
            {
                result["elapsedMs"] = sw.ElapsedMilliseconds;
                WriteJson(result);
            }
        }
        catch (ArgumentException ex)
        {
            WriteError(ex.Message, 400);
        }
        catch (Exception ex)
        {
            WriteError(ex.Message, 500);
        }

        Response.End(); // 結束請求，避免再渲染 HTML
    }

    // ===== 資料查詢 =====

    // 連線檢查：回報目前連到哪台伺服器、哪個資料庫
    private static Dictionary<string, object> Ping()
    {
        List<Dictionary<string, object>> rows = Query(
            "SELECT @@SERVERNAME AS [server], DB_NAME() AS [database], GETDATE() AS [time];",
            null);

        if (rows.Count == 0)
            throw new Exception("連線成功但沒有回傳資料");

        return rows[0];
    }

    // 依日期抓 OCAP：CREATE_TIME 落在 [當天 00:00:00, 隔天 00:00:00) 之間，
    // 且 OWNERDEPT 是 Sections 裡的其中一個。
    // 回傳時一併帶出 Sections，前端照這個順序固定版面、把 rows 填進對應的 section。
    private static Dictionary<string, object> QueryOcapByDay(string dateText)
    {
        DateTime day = ParseDate(dateText, "date");
        DateTime dayStart = day.Date;
        DateTime dayEnd = dayStart.AddDays(1);

        string sql = @"
SELECT
    UCHART_ID,
    CHART_SEQ,
    STATUS,
    CREATE_TIME,
    UPDATE_TIME,
    OWNERDEPT,
    CHART_NAME,
    CHART_GROUP,
    AREA,
    PARAMETER,
    PROCESSINGUNIT,
    RECIPE,
    LOT,
    CHART_OWNER,
    MEAS_EQUIPMENT
FROM " + OcapTable + @" WITH (NOLOCK)
WHERE CREATE_TIME >= @dayStart
  AND CREATE_TIME <  @dayEnd
  AND OWNERDEPT IN (" + SectionParameterList() + @")
ORDER BY OWNERDEPT ASC, CHART_NAME ASC, CREATE_TIME ASC;";

        List<Dictionary<string, object>> rows = Query(sql, delegate(SqlCommand cmd)
        {
            cmd.Parameters.Add("@dayStart", SqlDbType.DateTime).Value = dayStart;
            cmd.Parameters.Add("@dayEnd", SqlDbType.DateTime).Value = dayEnd;
            for (int i = 0; i < Sections.Length; i++)
                cmd.Parameters.Add("@dept" + i, SqlDbType.VarChar, 100).Value = Sections[i];
        });

        return new Dictionary<string, object> {
            { "date", dayStart.ToString("yyyy-MM-dd") },
            { "sections", Sections },
            { "rows", rows },
            { "truncated", rows.Count >= MaxRows }   // 超過 MaxRows 會被截斷，前端要提示
        };
    }

    // 單筆 OCAP 明細，並用 UCHART_ID/CHART_SEQ 對回 TF2_NPW_CHART 取得
    // MEAN_VALUE（Map 代理的 PointValue）、WAFER、MEASUREPU、PROCESSUNIT、CHART_TYPE、LASTDATATMST。
    // 找不到 NPW 對應列時 c.* 欄位為 null，前端仍可顯示 OCAP 本身的資料。
    private static Dictionary<string, object> QueryDetail(string uchartId, string chartSeq)
    {
        RequireIds(uchartId, chartSeq);

        string sql = @"
SELECT TOP (1)
    o.UCHART_ID,
    o.CHART_SEQ,
    o.CHART_NAME,
    o.STATUS,
    o.CREATE_TIME,
    o.OWNERDEPT,
    o.PROCESSINGUNIT,
    o.PARAMETER,
    o.RECIPE,
    o.LOT,
    o.MEAS_EQUIPMENT,
    o.CHART_OWNER,
    o.X_VIOLATED_RULE,
    o.HOLD_LOT_FLAG,
    o.HOLD_EQ_FLAG,
    o.CONTAINMENT_ACTION,
    o.CORRECTIVE_ACTION,
    o.ROOT_CAUSE,
    c.PROCESSUNIT,
    c.CHART_TYPE,
    c.MONITOR_TYPE,
    c.MEAN_VALUE,
    c.WAFER,
    c.MEASUREPU,
    c.UPDATE_TIME   AS NPW_UPDATE_TIME,
    c.LASTDATATMST
FROM " + OcapTable + @" o WITH (NOLOCK)
LEFT JOIN " + NpwChartTable + @" c WITH (NOLOCK)
       ON c.CHART_ID  = o.UCHART_ID
      AND c.CHART_SEQ = o.CHART_SEQ
WHERE o.UCHART_ID = @uchartId
  AND o.CHART_SEQ = @chartSeq
ORDER BY o.CREATE_TIME DESC;";

        List<Dictionary<string, object>> rows = Query(sql, delegate(SqlCommand cmd)
        {
            cmd.Parameters.Add("@uchartId", SqlDbType.VarChar, 20).Value = uchartId;
            cmd.Parameters.Add("@chartSeq", SqlDbType.VarChar, 20).Value = chartSeq;
        });

        if (rows.Count == 0)
            throw new ArgumentException("找不到 UCHART_ID=" + uchartId + " CHART_SEQ=" + chartSeq + " 的 OCAP 資料");

        return new Dictionary<string, object> { { "row", rows[0] } };
    }

    // Port：沿用 NPW 網站的規則，以 TF2_NPW_CHART 該筆的 LOT 對 MESI_DB.ews_lothist 的 LOTID
    //（LOT 結尾 _ADD 要去掉），取 LASTDATATMST 前後最近的一筆 EWS 記錄的 PORTID。
    //   ADDER (C-C)：只接受 LASTDATATMST 之前 7 天內、且 RECIPE 以 PPID 開頭的記錄
    //   NON-ADDER (XBAR)：前後 7 天內皆可，不比 RECIPE
    // 跨庫查詢較慢，前端在明細視窗開啟後才背景呼叫。
    private static Dictionary<string, object> QueryPort(string uchartId, string chartSeq)
    {
        RequireIds(uchartId, chartSeq);

        string sql = @"
SELECT DISTINCT lh.PORTID
FROM " + NpwChartTable + @" c WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP (1) h.PORTID
    FROM " + EwsLotHistTable + @" h WITH (NOLOCK)
    WHERE h.LOTID = CASE WHEN RIGHT(c.LOT, 4) = '_ADD' THEN LEFT(c.LOT, LEN(c.LOT) - 4) ELSE c.LOT END
      AND (c.CHART_TYPE = 'XBAR' OR c.RECIPE LIKE h.PPID + '%')
      AND h.JPTIME >= DATEADD(day, -7, c.LASTDATATMST)
      AND h.JPTIME <= CASE WHEN c.CHART_TYPE = 'C-C' THEN c.LASTDATATMST ELSE DATEADD(day, 7, c.LASTDATATMST) END
      AND h.PORTID IS NOT NULL
    ORDER BY ABS(DATEDIFF(second, h.JPTIME, c.LASTDATATMST))
) lh
WHERE c.CHART_ID  = @uchartId
  AND c.CHART_SEQ = @chartSeq
  AND c.LOT IS NOT NULL
  AND c.LASTDATATMST IS NOT NULL
  AND (c.CHART_TYPE = 'XBAR' OR c.RECIPE IS NOT NULL);";

        List<Dictionary<string, object>> rows = Query(sql, delegate(SqlCommand cmd)
        {
            cmd.Parameters.Add("@uchartId", SqlDbType.VarChar, 20).Value = uchartId;
            cmd.Parameters.Add("@chartSeq", SqlDbType.VarChar, 20).Value = chartSeq;
        });

        List<string> ports = new List<string>();
        foreach (Dictionary<string, object> r in rows)
        {
            string p = r["PORTID"] == null ? "" : Convert.ToString(r["PORTID"]).Trim();
            if (p.Length > 0 && !ports.Contains(p)) ports.Add(p);
        }
        ports.Sort();

        return new Dictionary<string, object> { { "ports", ports } };
    }

    // Trend chart 資料：該 CHART_ID 在 end 當天（含）往前 days 天的所有點，
    // 欄位對應 NPW 網站 drawSpark 用的 key（d/seq/xbar/sigma/ucl/lcl/avg1/avgn1/avg2/avgn2/mean/alarm/lot/wafer）。
    private static Dictionary<string, object> QueryChartData(string chartId, string endText, string daysText)
    {
        if (chartId.Length == 0)
            throw new ArgumentException("cid 必填");

        int days;
        if (!int.TryParse(daysText, out days) || days <= 0 || days > 400) days = 60;

        DateTime end = endText.Length == 0 ? DateTime.Today : ParseDate(endText, "end");
        DateTime endExcl = end.Date.AddDays(1);          // 含 end 當天
        DateTime start = endExcl.AddDays(-days);

        string sql = @"
SELECT
    CHART_SEQ,
    UPDATE_TIME,
    XBAR, SIGMA, UCL, LCL,
    AVG1STD, AVG_1STD, AVG2STD, AVG_2STD,
    MEAN_VALUE, ALARM_COUNT, LOT, WAFER
FROM " + NpwChartTable + @" WITH (NOLOCK)
WHERE CHART_ID = @chartId
  AND UPDATE_TIME >= @start
  AND UPDATE_TIME <  @endExcl
ORDER BY UPDATE_TIME ASC;";

        List<Dictionary<string, object>> rows = Query(sql, delegate(SqlCommand cmd)
        {
            cmd.Parameters.Add("@chartId", SqlDbType.VarChar, 20).Value = chartId;
            cmd.Parameters.Add("@start", SqlDbType.DateTime).Value = start;
            cmd.Parameters.Add("@endExcl", SqlDbType.DateTime).Value = endExcl;
        });

        List<object> series = new List<object>();
        foreach (Dictionary<string, object> r in rows)
        {
            series.Add(new Dictionary<string, object> {
                { "d",     r["UPDATE_TIME"] },
                { "seq",   r["CHART_SEQ"] },
                { "xbar",  r["XBAR"] },
                { "sigma", r["SIGMA"] },
                { "ucl",   r["UCL"] },
                { "lcl",   r["LCL"] },
                { "avg1",  r["AVG1STD"] },
                { "avgn1", r["AVG_1STD"] },
                { "avg2",  r["AVG2STD"] },
                { "avgn2", r["AVG_2STD"] },
                { "mean",  r["MEAN_VALUE"] },
                { "alarm", r["ALARM_COUNT"] },
                { "lot",   r["LOT"] },
                { "wafer", r["WAFER"] }
            });
        }

        return new Dictionary<string, object> {
            { "cid", chartId },
            { "start", start.ToString("yyyy-MM-dd") },
            { "end", end.ToString("yyyy-MM-dd") },
            { "series", series }
        };
    }

    // Wafer count（PM 後累計片數）：資料來源沿用 wafer_count 網站（pmwafercount.aspx.cs）。
    // tool 形如 SACVD-B06C / NISACVD-B03CB / TEOSPE-B01A / OXSE-A01，拆成 母機台(entity-字母數字) + 尾碼 chamber 字母。
    // scope 決定看哪一層：
    //   scope=MF      → 只回母機台（顯示為 -MF）；RECIPE 含 XFER 時前端用這個
    //   scope=CHAMBER → 只回尾碼字母對應的 chamber
    //   Tool_name 沒有 chamber 字母 → 不管 scope 一律視為 MF（機台本身就是母機台）
    // METERTYPE（AllowedMeters）：
    //   NISACVD → 套 wafer_count 網站的特殊對照（A-PM / B-PM / BUFFER-PM …）
    //   其他機台（含 SACVD 與 T_EQ2 的機台）→ chamber 看 WET_CLEAN，母機台看 BUFFER_WET_CLEAN
    // SPEC 取 _MeterTarget_DB09 同 EQCH+METERTYPE 最新一筆的 ALARM。
    private static Dictionary<string, object> QueryWaferCount(string tool, string scope)
    {
        bool mfOnly = string.Equals(scope, "MF", StringComparison.OrdinalIgnoreCase);
        string toolUp = (tool ?? "").Trim().ToUpperInvariant();

        string entity, mom, letters;
        Match m = Regex.Match(toolUp, @"^([A-Z0-9]+)-([A-Z])(\d{1,2})\s*([A-Z]*)");
        if (m.Success)
        {
            entity  = m.Groups[1].Value;
            mom     = entity + "-" + m.Groups[2].Value + m.Groups[3].Value.PadLeft(2, '0');
            letters = m.Groups[4].Value;
        }
        else
        {
            // 對不到慣用格式：整串當母機台名稱，沒有 chamber 資訊
            entity  = toolUp;
            mom     = toolUp;
            letters = "";
        }

        // 沒有 chamber 字母就是母機台本身 → 視為 MF
        bool noSuffixAsMf = !mfOnly && letters.Length == 0;
        if (noSuffixAsMf) mfOnly = true;

        List<string> eqpids = new List<string>();
        List<string> chambers = new List<string>();
        if (mfOnly)
        {
            eqpids.Add(mom);
        }
        else
        {
            foreach (char ch in letters)
            {
                string e = mom + ch;
                if (!eqpids.Contains(e)) { eqpids.Add(e); chambers.Add(e); }
            }
        }

        string[] ph = new string[eqpids.Count];
        for (int i = 0; i < ph.Length; i++) ph[i] = "@e" + i;

        string sql = @"
SELECT
    x.EQPID,
    x.METERTYPE,
    x.DATA_VAL,
    sp.SPEC_VAL
FROM " + UsageMeterTable + @" x
OUTER APPLY (
    SELECT TOP (1) t.ALARM AS SPEC_VAL
    FROM " + MeterTargetTable + @" t
    WHERE t.EQCH = x.EQPID AND t.METERTYPE = x.METERTYPE
    ORDER BY t.LASTREADINGTIME DESC
) sp
WHERE x.EQPID IN (" + string.Join(", ", ph) + @")
ORDER BY x.EQPID, x.METERTYPE;";

        List<Dictionary<string, object>> raw = Query(sql, delegate(SqlCommand cmd)
        {
            for (int i = 0; i < eqpids.Count; i++)
                cmd.Parameters.Add("@e" + i, SqlDbType.VarChar, 40).Value = eqpids[i];
        });

        // 依每台的 METERTYPE 規則過濾，並產生顯示用名稱
        List<object> rows = new List<object>();
        foreach (Dictionary<string, object> r in raw)
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

        return new Dictionary<string, object> {
            { "tool", tool },
            { "scope", mfOnly ? "MF" : "CHAMBER" },
            { "supported", true },
            { "entity", entity },
            { "mom", mom },
            { "chambers", chambers },
            { "noSuffixAsMf", noSuffixAsMf },   // true = Tool_name 沒有 chamber 字母，已改看 MF
            { "rows", rows }
        };
    }

    private static string[] AllowedMeters(string entity, string mom, bool isMf)
    {
        // NISACVD 以外（SACVD、T_EQ2 的機台…）：chamber → WET_CLEAN，母機台 → BUFFER_WET_CLEAN
        if (entity != "NISACVD")
            return isMf ? new string[] { "BUFFER_WET_CLEAN" } : new string[] { "WET_CLEAN" };

        // NISACVD
        if (isMf)
            return (mom == "NISACVD-B06" || mom == "NISACVD-B07" || mom == "NISACVD-B08")
                ? new string[] { "BUFFER_WET_CLEAN" }
                : new string[] { "BUFFER-PM" };
        return mom == "NISACVD-B01"
            ? new string[] { "A-PM", "B-PM" }
            : new string[] { "A-PM", "WET_CLEAN" };
    }

    // NON-ADDER Profile 圖：沿用 NPW 網站 op=profileimg 的做法。
    // 先抓 _Contour_Multi.asp，從中找 src 含 RAW 的 <img>（優先挑網址含該 WAFER 的）；
    // 入口頁有時只放 _Contour_Multi_DataShowMap.asp 的連結，就再跟進去找一次。
    private static Dictionary<string, object> FetchProfileImg(string chartId, string chartSeq, string pointValueRaw, string siteRaw, string wafer)
    {
        RequireIds(chartId, chartSeq);

        string site = Regex.Replace(siteRaw ?? "", "[^0-9A-Za-z]", "");
        if (!string.Equals(site, "12AP58", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(site, "12AP14", StringComparison.OrdinalIgnoreCase))
            site = "12AP58";
        string pointValue = Regex.Replace(pointValueRaw ?? "", "[^0-9.]", "");

        string entryUrl = SpcHost + "/Project1/_Contour_Multi.asp?site=" + Uri.EscapeDataString(site)
            + "&ChartID=" + Uri.EscapeDataString(chartId)
            + "&ChartSEQ=" + Uri.EscapeDataString(chartSeq)
            + (pointValue.Length > 0 ? "&PointValue=" + Uri.EscapeDataString(pointValue) : "");

        string html = HttpGetText(entryUrl);
        string imgUrl = ExtractRawImg(html, wafer);
        string usedUrl = entryUrl;

        if (imgUrl == null && !string.IsNullOrEmpty(html))
        {
            Match dm = Regex.Match(html, @"_Contour_Multi_DataShowMap\.asp\?[^""'<>\s]+", RegexOptions.IgnoreCase);
            if (dm.Success)
            {
                string dmUrl = HttpUtility.HtmlDecode(dm.Value).Replace("&amp;", "&");
                if (!dmUrl.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                    dmUrl = SpcHost + "/Project1/" + dmUrl.TrimStart('/');
                string dmHtml = HttpGetText(dmUrl);
                imgUrl = ExtractRawImg(dmHtml, wafer);
                usedUrl = dmUrl;
            }
        }

        return new Dictionary<string, object> {
            { "imgUrl", imgUrl },
            { "wafer", wafer },
            { "url", usedUrl }
        };
    }

    // 找 RAW contour 的 <img>；有指定 wafer 時優先挑網址含該 wafer 的那張
    private static string ExtractRawImg(string html, string wafer)
    {
        if (string.IsNullOrEmpty(html)) return null;
        MatchCollection matches = Regex.Matches(html, @"<img[^>]+src\s*=\s*['""]([^'""]+)['""]", RegexOptions.IgnoreCase);
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
        if (src.StartsWith("/")) return SpcHost + src;
        return SpcHost + "/Project1/" + src.TrimStart('~').TrimStart('/');
    }

    // 以伺服器身分（Windows 整合驗證）抓內網頁面
    private static string HttpGetText(string url)
    {
        HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
        req.Method = "GET";
        req.UserAgent = "Mozilla/5.0";
        req.Timeout = 15000;
        req.ReadWriteTimeout = 15000;
        req.AllowAutoRedirect = true;
        req.UseDefaultCredentials = true;
        req.Credentials = CredentialCache.DefaultCredentials;
        using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
        using (Stream stream = resp.GetResponseStream())
        {
            if (stream == null) return null;
            using (StreamReader sr = new StreamReader(stream, Encoding.UTF8))
                return sr.ReadToEnd();
        }
    }

    // ===== 共用工具 =====

    // 產生 "@dept0, @dept1, @dept2"，讓 Sections 用參數帶進 IN (...)
    private static string SectionParameterList()
    {
        string[] names = new string[Sections.Length];
        for (int i = 0; i < Sections.Length; i++) names[i] = "@dept" + i;
        return string.Join(", ", names);
    }

    private static DateTime ParseDate(string text, string paramName)
    {
        DateTime value;
        if (!DateTime.TryParseExact(text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out value))
            throw new ArgumentException(paramName + " 必須是 yyyy-MM-dd 格式，例如 2026-09-10");
        return value;
    }

    private static void RequireIds(string uchartId, string chartSeq)
    {
        if (uchartId.Length == 0 || chartSeq.Length == 0)
            throw new ArgumentException("uchart_id 與 chart_seq 必填");
    }

    // 只留數字（chart id / seq 都是數字），順便擋掉奇怪輸入
    private static string Digits(string value)
    {
        if (value == null) return "";
        string s = Regex.Replace(value, "[^0-9]", "");
        return s.Length > 20 ? s.Substring(0, 20) : s;
    }

    private static string GetConnectionString()
    {
        ConnectionStringSettings setting = ConfigurationManager.ConnectionStrings[ConnectionStringName];

        if (setting == null || string.IsNullOrWhiteSpace(setting.ConnectionString))
            throw new ConfigurationErrorsException(
                "Web.config 的 <connectionStrings> 找不到 \"" + ConnectionStringName + "\"");

        return setting.ConnectionString;
    }

    // 執行查詢並把每一列轉成「欄位名 → 值」的字典，換 SQL 不必改對應的類別
    private static List<Dictionary<string, object>> Query(string sql, Action<SqlCommand> bindParameters)
    {
        List<Dictionary<string, object>> rows = new List<Dictionary<string, object>>();

        using (SqlConnection conn = new SqlConnection(GetConnectionString()))
        {
            conn.Open();

            using (SqlCommand cmd = conn.CreateCommand())
            {
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = sql;
                cmd.CommandTimeout = CommandTimeoutSeconds;

                if (bindParameters != null) bindParameters(cmd);

                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    while (reader.Read() && rows.Count < MaxRows)
                    {
                        Dictionary<string, object> row = new Dictionary<string, object>();

                        for (int i = 0; i < reader.FieldCount; i++)
                        {
                            object value = reader.IsDBNull(i) ? null : reader.GetValue(i);

                            // JavaScriptSerializer 預設會把 DateTime 序列化成 \/Date(...)\/，先轉字串
                            if (value is DateTime)
                                value = ((DateTime)value).ToString("yyyy-MM-dd HH:mm:ss");

                            row[reader.GetName(i)] = value;
                        }

                        rows.Add(row);
                    }
                }
            }
        }

        return rows;
    }

    // 去除前後空白並限制長度，避免超長輸入直接進到查詢參數
    private static string Clean(string value, int maxLength)
    {
        if (value == null) return "";
        value = value.Trim();
        if (value.Length > maxLength) value = value.Substring(0, maxLength);
        return value;
    }

    private void WriteJson(object payload)
    {
        JavaScriptSerializer serializer = new JavaScriptSerializer();
        serializer.MaxJsonLength = int.MaxValue;
        Response.Write(serializer.Serialize(payload));
    }

    private void WriteError(string message, int statusCode)
    {
        Response.StatusCode = statusCode;
        WriteJson(new Dictionary<string, object> { { "error", message } });
    }
}
