<%@ Page Language="C#" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>

<script runat="server">
  // ===== AI 代理：前端不持有金鑰，由本頁從 Web.config 取金鑰轉呼叫 AI gateway =====
  // 前端 POST: { user, messages:[...] }（OpenAI Chat Completions 格式）
  // 本頁將 body 原樣轉送到 AiGatewayUrl，加上 api-key 標頭，並把回應原樣回傳。

  private void WriteJson(object obj, int status) {
    Response.StatusCode = status;
    Response.ContentType = "application/json; charset=utf-8";
    JavaScriptSerializer s = new JavaScriptSerializer();
    s.MaxJsonLength = int.MaxValue;
    Response.Write(s.Serialize(obj));
  }

  protected void Page_Load(object sender, EventArgs e) {
    try {
      string gateway = ConfigurationManager.AppSettings["AiGatewayUrl"];
      string apiKey  = ConfigurationManager.AppSettings["AiApiKey"];
      string apiVer  = ConfigurationManager.AppSettings["AiApiVersion"]; // 選填（Azure OpenAI 需要時才設）

      if (string.IsNullOrWhiteSpace(gateway)) {
        WriteJson(new Dictionary<string, object> { { "error", "Web.config 未設定 AiGatewayUrl" } }, 500);
        return;
      }

      // 讀前端 POST body（原樣轉送）
      string body = "";
      Request.InputStream.Position = 0;
      using (StreamReader sr = new StreamReader(Request.InputStream, Encoding.UTF8)) {
        body = sr.ReadToEnd();
      }
      if (string.IsNullOrEmpty(body)) body = "{}";

      // 組目標 URL（如有設定 api-version 則附上）
      string url = gateway;
      if (!string.IsNullOrWhiteSpace(apiVer)) {
        url += (url.IndexOf('?') >= 0 ? "&" : "?") + "api-version=" + Uri.EscapeDataString(apiVer);
      }

      ServicePointManager.SecurityProtocol =
        SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
      ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };

      HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
      req.Method = "POST";
      req.ContentType = "application/json";
      req.Timeout = 120000;
      req.ReadWriteTimeout = 120000;
      if (!string.IsNullOrWhiteSpace(apiKey)) {
        req.Headers["api-key"] = apiKey;                      // Azure OpenAI 風格
        req.Headers["Authorization"] = "Bearer " + apiKey;    // 兼容 Bearer 風格
      }

      byte[] data = Encoding.UTF8.GetBytes(body);
      req.ContentLength = data.Length;
      using (Stream rs = req.GetRequestStream()) { rs.Write(data, 0, data.Length); }

      int code = 200;
      string respText = "";
      try {
        using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
        using (StreamReader rdr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8)) {
          code = (int)resp.StatusCode;
          respText = rdr.ReadToEnd();
        }
      } catch (WebException wex) {
        HttpWebResponse resp = wex.Response as HttpWebResponse;
        if (resp != null) {
          code = (int)resp.StatusCode;
          using (StreamReader rdr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8)) {
            respText = rdr.ReadToEnd();
          }
        } else {
          WriteJson(new Dictionary<string, object> { { "error", "呼叫 AI gateway 失敗：" + wex.Message } }, 502);
          return;
        }
      }

      // 原樣回傳 gateway 回應（前端可解析 choices 或 reply）
      Response.StatusCode = code;
      Response.ContentType = "application/json; charset=utf-8";
      Response.Write(respText);

    } catch (Exception ex) {
      WriteJson(new Dictionary<string, object> { { "error", ex.Message } }, 500);
    }
  }
</script>
