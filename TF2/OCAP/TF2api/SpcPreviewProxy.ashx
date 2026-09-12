<%@ WebHandler Language="C#" Class="SpcPreviewProxy" %>

using System;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;

public class SpcPreviewProxy : IHttpHandler
{
    // GET /TF2api/SpcPreviewProxy.ashx?chartId=85766
    // Response: { ok:true, imageUrl:"http://f12aesiap03/TempFile/navi_SPC__...jpg" }
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Charset = "utf-8";

        try
        {
            string chartIdRaw = (context.Request["chartId"] ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(chartIdRaw))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "chartId required" });
                return;
            }

            // chartId should be digits only
            string chartId = Regex.Replace(chartIdRaw, "[^0-9]", "");
            if (string.IsNullOrWhiteSpace(chartId))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "invalid chartId" });
                return;
            }

            // Allow caller to specify site (default 12AP58)
            // Example: /TF2api/SpcPreviewProxy.ashx?chartId=85766&site=12AP14
            string site = (context.Request["site"] ?? "12AP58").Trim();
            site = Regex.Replace(site, "[^0-9A-Za-z]", "");
            if (string.IsNullOrWhiteSpace(site)) site = "12AP58";

            // Only allow known sites (avoid SSRF/parameter abuse)
            if (!string.Equals(site, "12AP58", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(site, "12AP14", StringComparison.OrdinalIgnoreCase))
            {
                site = "12AP58";
            }

            // Build the page URL (same as front-end buildChartUrl)
            string pageUrl = "http://10.10.101.170/projectsite/SPCTool/PreviewMultiSPCTypeChart.aspx" +
                             "?site=" + Uri.EscapeDataString(site) +
                             "&ChartList=NPW:" + Uri.EscapeDataString(chartId) +
                             "&DataCount=50" +
                             "&DataType=OFFSPC";

            string html = HttpGetText(pageUrl, context);
            if (string.IsNullOrWhiteSpace(html))
            {
                context.Response.StatusCode = 502;
                WriteJson(context, new { ok = false, error = "empty response" });
                return;
            }

            // Try to find the generated preview JPG
            // Examples:
            //   /TempFile/navi_SPC__85766_xxx_C-C.jpg
            //   http://f12aesiap03/TempFile/navi_SPC__85766_xxx_C-C.jpg
            // 注意：Regex 字串內的 \" 在 @"" 中不合法，改用 "" 來表達雙引號
            var re = new Regex(@"(?:https?://f12aesiap03)?/TempFile/navi_SPC__" + chartId + @"_[^""'\s>]+?\.jpg", RegexOptions.IgnoreCase);
            var m = re.Match(html);
            if (!m.Success)
            {
                // Not found: return ok but null imageUrl
                WriteJson(context, new { ok = true, imageUrl = (string)null, pageUrl = pageUrl });
                return;
            }

            string imageUrl = m.Value;
            if (imageUrl.StartsWith("/", StringComparison.Ordinal))
            {
                imageUrl = "http://f12aesiap03" + imageUrl;
            }

            WriteJson(context, new { ok = true, imageUrl = imageUrl, pageUrl = pageUrl });
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            WriteJson(context, new { ok = false, error = ex.Message });
        }
    }

    private static string HttpGetText(string url, HttpContext ctx)
    {
        var req = (HttpWebRequest)WebRequest.Create(url);
        req.Method = "GET";
        req.UserAgent = "Mozilla/5.0";
        req.Timeout = 15000;
        req.ReadWriteTimeout = 15000;
        req.AllowAutoRedirect = true;

        // Try Windows Integrated Authentication (NTLM/Kerberos)
        // This is required when SPCTool uses IIS Windows Authentication.
        req.UseDefaultCredentials = true;
        req.Credentials = CredentialCache.DefaultCredentials;

        // Forward cookies from the current request (if any) to avoid auth issues.
        // This helps when SPCTool requires authentication cookies.
        try
        {
            req.CookieContainer = new CookieContainer();
            if (ctx != null && ctx.Request != null && ctx.Request.Cookies != null)
            {
                foreach (string key in ctx.Request.Cookies)
                {
                    var c = ctx.Request.Cookies[key];
                    if (c == null) continue;
                    try
                    {
                        req.CookieContainer.Add(new Uri(url), new Cookie(c.Name, c.Value, c.Path, c.Domain));
                    }
                    catch
                    {
                        // ignore malformed cookies
                    }
                }
            }
        }
        catch
        {
            // ignore
        }

        try
        {
            using (var resp = (HttpWebResponse)req.GetResponse())
        using (var stream = resp.GetResponseStream())
        {
            if (stream == null) return null;
            using (var sr = new StreamReader(stream, Encoding.UTF8))
            {
                return sr.ReadToEnd();
            }
        }
        }
        catch (WebException wex)
        {
            // Include status code for troubleshooting (e.g., 401 Unauthorized)
            var httpResp = wex.Response as HttpWebResponse;
            string code = httpResp != null ? ((int)httpResp.StatusCode).ToString() : "";
            string status = httpResp != null ? httpResp.StatusCode.ToString() : "";

            string body = null;
            try
            {
                if (httpResp != null && httpResp.GetResponseStream() != null)
                {
                    using (var sr = new StreamReader(httpResp.GetResponseStream(), Encoding.UTF8))
                    {
                        body = sr.ReadToEnd();
                    }
                }
            }
            catch { }

            throw new Exception("HTTP " + code + " " + status + (string.IsNullOrWhiteSpace(body) ? "" : ("\n" + body)));
        }
    }

    private static void WriteJson(HttpContext ctx, object obj)
    {
        var ser = new JavaScriptSerializer();
        ctx.Response.Write(ser.Serialize(obj));
    }

    public bool IsReusable { get { return true; } }
}

