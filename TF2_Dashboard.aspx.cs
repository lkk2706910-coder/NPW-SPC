using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;

// TF2 SPC 儀表板 — 後端資料（code-behind）
// 規則：請求帶 ?tab=... → 回傳 JSON（資料 API）；無參數 → 由 .aspx 渲染前端 HTML
public partial class TF2_Dashboard : Page
{
    public class SpcRow
    {
        public string CHART_NAME;
        public object UPDATE_TIME;
        public decimal? MEAN_VALUE;
        public decimal? XBAR;
        public decimal? SIGMA;
        public decimal? UCL;
        public string RECIPE;
        public string PARAMETER;
        public string PROCESSUNIT;
        public string CHART_ID;
        public string CHART_SEQ;
    }

    private static string GetConnStr()
    {
        ConnectionStringSettings cs = ConfigurationManager.ConnectionStrings["SpcDb"];
        if (cs != null && !string.IsNullOrWhiteSpace(cs.ConnectionString))
            return cs.ConnectionString;
        string cs2 = ConfigurationManager.AppSettings["SpcDb"];
        if (!string.IsNullOrWhiteSpace(cs2))
            return cs2;
        return "Server=UMCESIDB02;Database=GPTPoCDB;User ID=GPTPoCDBUser;Password=DB02.2026;TrustServerCertificate=True;";
    }

    private static string Safe(string s, int maxLen)
    {
        if (s == null) return "";
        s = s.Trim();
        if (s.Length > maxLen) s = s.Substring(0, maxLen);
        return s;
    }

    private void WriteJson(object obj)
    {
        JavaScriptSerializer serializer = new JavaScriptSerializer();
        serializer.MaxJsonLength = int.MaxValue;
        Response.Write(serializer.Serialize(obj));
    }

    private void WriteJson(object obj, int status)
    {
        Response.StatusCode = status;
        Response.ContentType = "application/json; charset=utf-8";
        WriteJson(obj);
    }

    // ===== AI 代理（?ai=1, POST {user, messages}）=====
    // 前端不持有金鑰，由本頁從 Web.config 取金鑰轉呼叫 AI gateway，回應原樣回傳
    private void HandleAiProxy()
    {
        Response.Clear();
        try
        {
            string gateway = ConfigurationManager.AppSettings["AiGatewayUrl"];
            string apiKey  = ConfigurationManager.AppSettings["AiApiKey"];
            string apiVer  = ConfigurationManager.AppSettings["AiApiVersion"]; // 選填

            if (string.IsNullOrWhiteSpace(gateway))
            {
                WriteJson(new Dictionary<string, object> { { "error", "Web.config 未設定 AiGatewayUrl" } }, 500);
            }
            else
            {
                string body = "";
                Request.InputStream.Position = 0;
                using (StreamReader sr = new StreamReader(Request.InputStream, Encoding.UTF8)) { body = sr.ReadToEnd(); }
                if (string.IsNullOrEmpty(body)) body = "{}";

                string url = gateway;
                if (!string.IsNullOrWhiteSpace(apiVer))
                    url += (url.IndexOf('?') >= 0 ? "&" : "?") + "api-version=" + Uri.EscapeDataString(apiVer);

                ServicePointManager.SecurityProtocol =
                    SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };

                HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
                req.Method = "POST";
                req.ContentType = "application/json";
                req.Timeout = 120000;
                req.ReadWriteTimeout = 120000;
                if (!string.IsNullOrWhiteSpace(apiKey))
                {
                    req.Headers["api-key"] = apiKey;                   // Azure OpenAI 風格
                    req.Headers["Authorization"] = "Bearer " + apiKey; // 兼容 Bearer 風格
                }

                byte[] data = Encoding.UTF8.GetBytes(body);
                req.ContentLength = data.Length;
                using (Stream rs = req.GetRequestStream()) { rs.Write(data, 0, data.Length); }

                int code = 200;
                string respText = "";
                try
                {
                    using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
                    using (StreamReader rdr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
                    {
                        code = (int)resp.StatusCode;
                        respText = rdr.ReadToEnd();
                    }
                }
                catch (WebException wex)
                {
                    HttpWebResponse resp = wex.Response as HttpWebResponse;
                    if (resp != null)
                    {
                        code = (int)resp.StatusCode;
                        using (StreamReader rdr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8)) { respText = rdr.ReadToEnd(); }
                    }
                    else
                    {
                        code = 502;
                        respText = new JavaScriptSerializer().Serialize(
                            new Dictionary<string, object> { { "error", "呼叫 AI gateway 失敗：" + wex.Message } });
                    }
                }

                Response.StatusCode = code;
                Response.ContentType = "application/json; charset=utf-8";
                Response.Write(respText);
            }
        }
        catch (Exception ex)
        {
            WriteJson(new Dictionary<string, object> { { "error", ex.Message } }, 500);
        }
        Response.End(); // 結束請求，避免再渲染 HTML
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // AI 代理：?ai=1（POST）
        if (Safe(Request["ai"], 4) == "1") { HandleAiProxy(); return; }

        string tab = Safe(Request["tab"], 30);

        // 無 tab 參數 → 顯示前端 HTML（由 .aspx 標記渲染，這裡不處理）
        if (tab.Length == 0) return;

        // 有 tab → 回傳 JSON（資料 API）
        Response.Clear();
        Response.ContentType = "application/json; charset=utf-8";

        tab = tab.ToUpperInvariant();

        string chartName = Safe(Request["chartName"], 200);
        if (chartName.Length == 0) chartName = "ALL";

        // mode: ADDER / PARTITION / UTHK
        string mode = "ADDER";
        if (tab == "PARTITION" || tab == "THK")
        {
            mode = "PARTITION";
        }
        else if (tab == "U" || tab == "U%" || tab == "UTHK" || tab == "THK-U" || tab == "THK_U")
        {
            mode = "UTHK";
        }

        string connStr = GetConnStr();
        if (string.IsNullOrWhiteSpace(connStr))
        {
            Response.StatusCode = 500;
            WriteJson(new Dictionary<string, object> { { "error", "empty connection string" } });
        }
        else
        {
            try
            {
                List<SpcRow> rows = new List<SpcRow>();

                using (SqlConnection conn = new SqlConnection())
                {
                    conn.ConnectionString = connStr;
                    conn.Open();

                    using (SqlCommand cmd = conn.CreateCommand())
                    {
                        cmd.CommandType = CommandType.Text;

                        // 分頁分類依 CHART_NAME 關鍵字：
                        //   Partition = CHART_NAME 含 'LTPA' 或 'PAR_'（PAR[_] 為字面底線，避免誤中結尾的 [Partition...]）
                        //   ADDER     = 其餘（含 -PA-）
                        //   UTHK(U%)  = PARAMETER LIKE '%THK-U%'
                        cmd.CommandText = @"
WITH s AS (
  SELECT
    CHART_NAME,
    UPDATE_TIME,
    MEAN_VALUE,
    XBAR,
    SIGMA,
    UCL,
    RECIPE,
    PARAMETER,
    PROCESSUNIT,
    CHART_ID,
    CHART_SEQ,
    ROW_NUMBER() OVER (PARTITION BY CHART_NAME ORDER BY UPDATE_TIME DESC) AS rn
  FROM GPTDB_USPC.dbo.TF2_NPW_CHART WITH (NOLOCK)
  WHERE
    (
      (@mode = 'UTHK' AND PARAMETER LIKE '%THK-U%')
      OR
      (@mode <> 'UTHK' AND PARAMETER = 'ADDER')
    )
    AND (
      PROCESSUNIT LIKE 'NISACVD%'
      OR PROCESSUNIT LIKE 'SACVD%'
    )
    AND (@chartName = 'ALL' OR CHART_NAME LIKE '%' + @chartName + '%')
    AND (
      (@mode = 'ADDER' AND CHART_NAME NOT LIKE '%LTPA%' AND CHART_NAME NOT LIKE '%PAR[_]%')
      OR
      (@mode = 'PARTITION' AND (CHART_NAME LIKE '%LTPA%' OR CHART_NAME LIKE '%PAR[_]%'))
      OR
      (@mode = 'UTHK')
    )
)
SELECT
  CHART_NAME,
  UPDATE_TIME,
  MEAN_VALUE,
  XBAR,
  SIGMA,
  UCL,
  RECIPE,
  PARAMETER,
  PROCESSUNIT,
  CHART_ID,
  CHART_SEQ
FROM s
WHERE rn <= 30
ORDER BY CHART_NAME ASC, UPDATE_TIME ASC;
";

                        cmd.Parameters.Add("@chartName", SqlDbType.VarChar, 200).Value = chartName;
                        cmd.Parameters.Add("@mode", SqlDbType.VarChar, 30).Value = mode;

                        using (SqlDataReader rdr = cmd.ExecuteReader())
                        {
                            while (rdr.Read())
                            {
                                SpcRow r = new SpcRow();
                                r.CHART_NAME = rdr["CHART_NAME"] == DBNull.Value ? null : Convert.ToString(rdr["CHART_NAME"]);
                                r.UPDATE_TIME = rdr["UPDATE_TIME"] == DBNull.Value ? null : rdr["UPDATE_TIME"];
                                r.MEAN_VALUE = rdr["MEAN_VALUE"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(rdr["MEAN_VALUE"]);
                                r.XBAR = rdr["XBAR"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(rdr["XBAR"]);
                                r.SIGMA = rdr["SIGMA"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(rdr["SIGMA"]);
                                r.UCL = rdr["UCL"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(rdr["UCL"]);
                                r.RECIPE = rdr["RECIPE"] == DBNull.Value ? null : Convert.ToString(rdr["RECIPE"]);
                                r.PARAMETER = rdr["PARAMETER"] == DBNull.Value ? null : Convert.ToString(rdr["PARAMETER"]);
                                r.PROCESSUNIT = rdr["PROCESSUNIT"] == DBNull.Value ? null : Convert.ToString(rdr["PROCESSUNIT"]);
                                r.CHART_ID = rdr["CHART_ID"] == DBNull.Value ? null : Convert.ToString(rdr["CHART_ID"]);
                                r.CHART_SEQ = rdr["CHART_SEQ"] == DBNull.Value ? null : Convert.ToString(rdr["CHART_SEQ"]);
                                rows.Add(r);
                            }
                        }
                    }
                }

                WriteJson(new Dictionary<string, object> {
                    { "tab", tab },
                    { "rows", rows }
                });
            }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                WriteJson(new Dictionary<string, object> { { "error", ex.Message } });
            }
        }

        Response.End(); // 結束請求，避免再渲染 HTML
    }
}
