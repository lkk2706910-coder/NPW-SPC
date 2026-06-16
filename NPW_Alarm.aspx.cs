using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;

// No-auth home page + AI chat proxy.
//
// Routes:
//   GET  NPW_Alarm.aspx            -> renders the page (no auth required)
//   POST NPW_Alarm.aspx?op=chat    -> proxy to LLM
//
// The page itself is rendered by NPW_Alarm.aspx markup; this code-behind
// only handles the chat API op. DB queries from your own .aspx pages
// go through DbHelper directly.
public partial class NPW_Alarm : Page
{
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
        // Otherwise fall through to render the page.
    }

    // ISO 週數（用於 W## 標籤）
    private static int IsoWeek(DateTime d)
    {
        var cal = System.Globalization.CultureInfo.InvariantCulture.Calendar;
        DayOfWeek day = cal.GetDayOfWeek(d);
        if (day >= DayOfWeek.Monday && day <= DayOfWeek.Wednesday) d = d.AddDays(3);
        return cal.GetWeekOfYear(d, System.Globalization.CalendarWeekRule.FirstFourDayWeek, DayOfWeek.Monday);
    }

    // NPW 週 alarm 報表用的「週原始資料」。?date=YYYY-MM-DD（週內任一天，預設今天）
    //
    // 沿用原工具(TF2_NPW.html)的判讀邏輯，由前端 JS 做彙總；後端只負責把該週
    // 需要的欄位撈出來。對應規則：
    //   - 資料區間：週二~週一（以 UPDATE_TIME 分日）
    //   - ADDER / NON-ADDER：CHART_TYPE 'C-C' / 'XBAR'
    //   - Entity：PROCESSUNIT 取 '-' 前字串（只看 NISACVD / SACVD）
    //   - 排除 Engineering：CHART_DESC <> 'Engineering'
    //   - MONITOR_TYPE = 'NORMAL'
    //   - Alarm：ALARM_COUNT >= 1（前端判斷）
    // 預先過濾的條件都只會剔除前端本來就會丟掉的列，故不影響結果，只是縮小傳輸量。
    private void HandleAlarm()
    {
        DateTime refDate;
        if (!DateTime.TryParse(Request.QueryString["date"], out refDate)) refDate = DateTime.Today;
        // 週起點 = 不晚於 refDate 的最近「週二」
        int diff = (((int)refDate.DayOfWeek) - ((int)DayOfWeek.Tuesday) + 7) % 7;
        DateTime weekStart = refDate.Date.AddDays(-diff);   // 週二
        DateTime weekEndExcl = weekStart.AddDays(7);        // 下週二(不含)
        DateTime weekEnd = weekStart.AddDays(6);            // 週一

        var days = new List<string>();
        for (int i = 0; i < 7; i++) days.Add(weekStart.AddDays(i).ToString("yyyy-MM-dd"));

        string sql =
            "SELECT PROCESSUNIT, CONVERT(varchar(10), UPDATE_TIME, 23) AS UPDATE_TIME, " +
            "MONITOR_TYPE, CHART_TYPE, CHART_NAME, CHART_ID, CHART_DESC, ALARM_COUNT " +
            "FROM GPTDB_USPC.dbo.TF2_NPW_CHART WITH (NOLOCK) " +
            "WHERE UPDATE_TIME >= @p0 AND UPDATE_TIME < @p1 " +
            "AND MONITOR_TYPE = 'NORMAL' " +
            "AND ISNULL(CHART_DESC,'') <> 'Engineering' " +
            "AND CHART_TYPE IN ('C-C','XBAR') " +
            "AND (PROCESSUNIT LIKE 'NISACVD%' OR PROCESSUNIT LIKE 'SACVD%')";
        var rows = DbHelper.QueryRows(sql, weekStart, weekEndExcl);

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

    // 讀取 GPTDB_USPC.dbo.TF2_NPW_CHART，回傳 JSON。
    // 選填查詢參數：?area=TF2  &pu=NISACVD  &top=200
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

        string sql = "SELECT TOP " + top + " * FROM GPTDB_USPC.dbo.TF2_NPW_CHART WITH (NOLOCK)"
                     + where + " ORDER BY UPDATE_TIME DESC";
        var rows = DbHelper.QueryRows(sql, args.ToArray());

        // DateTime → 字串，方便前端顯示（避免 /Date(ms)/）
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
        byte[] payloadBytes = Encoding.UTF8.GetBytes(ser.Serialize(payload));

        var hreq = (HttpWebRequest)WebRequest.Create(url);
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
            Response.StatusCode = status;
            Response.Write("{\"ok\":false,\"error\":\"" + JsonEscape(wex.Message) + "\",\"detail\":" + ser.Serialize(detail) + "}");
        }
    }

    private static string JsonEscape(string s)
    {
        if (s == null) return "";
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "");
    }
}
