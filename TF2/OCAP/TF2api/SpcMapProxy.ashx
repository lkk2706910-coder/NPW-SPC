<%@ WebHandler Language="C#" Class="SpcMapProxy" %>
<!-- Deprecated: MAP 功能已在 TF2_EQ2 NPW.html 中移除，保留檔案避免舊連結 404 -->

using System;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;

public class SpcMapProxy : IHttpHandler
{
    // GET /TF2api/SpcMapProxy.ashx?chartId=85766&chartSeq=1832
    // Response: { ok:true, waferInfoId:"510992248", mapUrl:"http://10.10.101.170/Project1/_Blob_Single_WaferInfo.asp?WAFERINFOID=..." }
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Charset = "utf-8";

        try
        {
            string chartIdRaw = (context.Request["chartId"] ?? string.Empty).Trim();
            string chartSeqRaw = (context.Request["chartSeq"] ?? string.Empty).Trim();

            if (string.IsNullOrWhiteSpace(chartIdRaw) || string.IsNullOrWhiteSpace(chartSeqRaw))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "chartId/chartSeq required" });
                return;
            }

            string chartId = Regex.Replace(chartIdRaw, "[^0-9]", "");
            string chartSeq = Regex.Replace(chartSeqRaw, "[^0-9]", "");
            if (string.IsNullOrWhiteSpace(chartId) || string.IsNullOrWhiteSpace(chartSeq))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "invalid chartId/chartSeq" });
                return;
            }

                        // 改用 _Blob_ShowImage_4WebResultLoop 取得 WaferInfoID（你提供的頁面內容最完整、穩定）
            // 需要 PointValue (前端提供 MEAN_VALUE)
            string pointValueRaw = (context.Request["pointValue"] ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(pointValueRaw))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "pointValue required" });
                return;
            }

            // Keep digits and dot (MEAN_VALUE may be decimal)
            string pointValue = Regex.Replace(pointValueRaw, "[^0-9.]", "");
            if (string.IsNullOrWhiteSpace(pointValue))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "invalid pointValue" });
                return;
            }

            string loopUrl = "http://10.10.101.170/Project1/_Blob_ShowImage_4WebResultLoop.asp" +
                             "?site=12AP58" +
                             "&uchart_id=" + Uri.EscapeDataString(chartId) +
                             "&chart_seq=" + Uri.EscapeDataString(chartSeq) +
                             "&PointValue=" + Uri.EscapeDataString(pointValue);

            string loopHtml = HttpGetText(loopUrl, context);

            // Find WaferInfoID
            var m = Regex.Match(loopHtml ?? string.Empty, @"WAFERINFOID\s*=\s*(\d+)", RegexOptions.IgnoreCase);
            if (!m.Success)
            {
                m = Regex.Match(loopHtml ?? string.Empty, @"WaferInfoID\s*[:=]+\s*(\d+)", RegexOptions.IgnoreCase);
            }

            if (!m.Success)
            {
                WriteJson(context, new { ok = true, waferInfoId = (string)null, mapUrl = (string)null, mapImgUrl = (string)null, loopUrl = loopUrl, debug = "WAFERINFOID not found" });
                return;
            }

            string waferInfoId = m.Groups[1].Value;
            string mapUrl = "http://10.10.101.170/Project1/_Blob_Single_WaferInfo.asp?WAFERINFOID=" + Uri.EscapeDataString(waferInfoId);


            // Now fetch the map page itself and extract the real image src
            string mapImgUrl = null;
            try
            {
                // 直接從 mapUrl 的 HTML 內抓出 ADDER 欄位那張圖：
                // <td ...><center><img src='_Blob_Single_WaferInfo.asp?WAFERINFOID=510992248'>
                string mapHtml = HttpGetText(mapUrl, context);

                var imgMatch = Regex.Match(mapHtml ?? string.Empty,
                    "<img[^>]+src=['\"]([^'\"]+)['\"][^>]*WAFERINFOID=" + Regex.Escape(waferInfoId),
                    RegexOptions.IgnoreCase);

                // fallback: 第一個 img
                if(!imgMatch.Success)
                {
                    imgMatch = Regex.Match(mapHtml ?? string.Empty,
                        "<img[^>]+src=['\"]([^'\"]+)['\"]",
                        RegexOptions.IgnoreCase);
                }

                string src = null;
                if (imgMatch.Success)
                {
                    src = imgMatch.Groups[1].Value;
                }

                if (!string.IsNullOrWhiteSpace(src))
                {
                    if (src.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                    {
                        mapImgUrl = src;
                    }
                    else if (src.StartsWith("/", StringComparison.Ordinal))
                    {
                        mapImgUrl = "http://10.10.101.170" + src;
                    }
                    else
                    {
                        mapImgUrl = "http://10.10.101.170/Project1/" + src.TrimStart('~').TrimStart('/');
                    }
                }
            }
            catch { }

            WriteJson(context, new { ok = true, waferInfoId = waferInfoId, mapUrl = mapUrl, mapImgUrl = mapImgUrl, loopUrl = loopUrl });
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

        // Windows Integrated Authentication
        req.UseDefaultCredentials = true;
        req.Credentials = CredentialCache.DefaultCredentials;

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

    private static void WriteJson(HttpContext ctx, object obj)
    {
        var ser = new JavaScriptSerializer();
        ctx.Response.Write(ser.Serialize(obj));
    }

    public bool IsReusable { get { return true; } }
}
