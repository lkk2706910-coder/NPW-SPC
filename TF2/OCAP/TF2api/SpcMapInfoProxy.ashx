<%@ WebHandler Language="C#" Class="SpcMapInfoProxy" %>

using System;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections.Generic;

public class SpcMapInfoProxy : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Charset = "utf-8";

        try
        {
            string site = (context.Request["site"] ?? "12AP58").Trim();
            site = Regex.Replace(site, "[^0-9A-Za-z]", "");
            if (string.IsNullOrWhiteSpace(site)) site = "12AP58";
            if (!string.Equals(site, "12AP58", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(site, "12AP14", StringComparison.OrdinalIgnoreCase))
                site = "12AP58";

            string uchartIdRaw   = (context.Request["uchart_id"]  ?? context.Request["uchartId"]  ?? string.Empty).Trim();
            string chartSeqRaw   = (context.Request["chart_seq"]   ?? context.Request["chartSeq"]  ?? string.Empty).Trim();
            string pointValueRaw = (context.Request["PointValue"]  ?? context.Request["pointValue"] ?? "10").Trim();

            string uchartId   = Regex.Replace(uchartIdRaw,   "[^0-9]",  "");
            string chartSeq   = Regex.Replace(chartSeqRaw,   "[^0-9]",  "");
            string pointValue = Regex.Replace(pointValueRaw, "[^0-9.]", "");
            if (string.IsNullOrWhiteSpace(pointValue)) pointValue = "10";

            if (string.IsNullOrWhiteSpace(uchartId) || string.IsNullOrWhiteSpace(chartSeq))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "uchart_id/chart_seq required" });
                return;
            }

            string url = "http://10.10.101.170/Project1/_Blob_ShowImage_4WebResultLoop.asp" +
                         "?site="       + Uri.EscapeDataString(site)       +
                         "&uchart_id="  + Uri.EscapeDataString(uchartId)   +
                         "&chart_seq="  + Uri.EscapeDataString(chartSeq)   +
                         "&PointValue=" + Uri.EscapeDataString(pointValue);

            string html = HttpGetText(url, context);
            if (string.IsNullOrWhiteSpace(html))
            {
                context.Response.StatusCode = 502;
                WriteJson(context, new { ok = false, error = "empty response", url = url });
                return;
            }

            // ── MeasurePU ──────────────────────────────────────────────────────────
            string measurePU = null;
            var m1 = Regex.Match(html,
                @"MeasurePU\s*\([^)]*\)\s*:\s*=\s*<font[^>]*>\s*([^<\r\n]+)\s*</font>",
                RegexOptions.IgnoreCase);
            if (m1.Success)
                measurePU = HttpUtility.HtmlDecode(m1.Groups[1].Value.Trim());
            else
            {
                var m2 = Regex.Match(html,
                    @"MeasurePU[^<]*<font[^>]*>\s*([^<\r\n]+)\s*</font>",
                    RegexOptions.IgnoreCase);
                if (m2.Success) measurePU = HttpUtility.HtmlDecode(m2.Groups[1].Value.Trim());
            }

            // 只取最後一段，例如 "KLA-Tencor^SP5^CUSFSCAN-B06" → "CUSFSCAN-B06"
            if (!string.IsNullOrWhiteSpace(measurePU) && measurePU.Contains("^"))
            {
                measurePU = measurePU.Substring(measurePU.LastIndexOf('^') + 1).Trim();
            }

            // ── 掃全頁所有 WaferMap img，依序: PRE=0, POST=1, BASELINE=2, ADDER=3 ──
            string preWaferInfoId   = null;
            string adderWaferInfoId = null;

            var waferImgMatches = Regex.Matches(
                html,
                @"_Blob_Single_WaferInfo\.asp\?WAFERINFOID=(\d+)",
                RegexOptions.IgnoreCase
            );

            // 去重複後依序收集
            var waferIds = new List<string>();
            foreach (Match wm in waferImgMatches)
            {
                string wid = wm.Groups[1].Value;
                if (!waferIds.Contains(wid))
                    waferIds.Add(wid);
            }

            // 順序: [0]=PRE, [1]=POST, [2]=BASELINE, [3]=ADDER
            if (waferIds.Count >= 1) preWaferInfoId   = waferIds[0];
            if (waferIds.Count >= 4) adderWaferInfoId = waferIds[3];

            // fallback: Surfscan WaferInfoID → ADDER
            if (string.IsNullOrWhiteSpace(adderWaferInfoId))
            {
                var ms = Regex.Match(html,
                    @"Surfscan\s+WaferInfoID\s*:\s*=\s*<font[^>]*>\s*(\d+)\s*</font>",
                    RegexOptions.IgnoreCase);
                if (ms.Success) adderWaferInfoId = ms.Groups[1].Value;
            }

            // ── 組圖片 URL ─────────────────────────────────────────────────────────
            string baseImgUrl     = "http://10.10.101.170/Project1/_Blob_Single_WaferInfo.asp?WAFERINFOID=";
            string adderMapImgUrl = !string.IsNullOrWhiteSpace(adderWaferInfoId) ? baseImgUrl + Uri.EscapeDataString(adderWaferInfoId) : null;
            string preMapImgUrl   = !string.IsNullOrWhiteSpace(preWaferInfoId)   ? baseImgUrl + Uri.EscapeDataString(preWaferInfoId)   : null;

            // ── 回傳 ───────────────────────────────────────────────────────────────
            WriteJson(context, new
            {
                ok        = true,
                site      = site,
                uchart_id = uchartId,
                chart_seq = chartSeq,
                PointValue = pointValue,
                measurePU  = measurePU,
                adderWaferInfoId = adderWaferInfoId,
                adderMapImgUrl   = adderMapImgUrl,
                preWaferInfoId   = preWaferInfoId,
                preMapImgUrl     = preMapImgUrl,
                debug_waferIds   = waferIds.ToArray(),
                url = url
            });
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
        req.Method            = "GET";
        req.UserAgent         = "Mozilla/5.0";
        req.Timeout           = 15000;
        req.ReadWriteTimeout  = 15000;
        req.AllowAutoRedirect = true;
        req.UseDefaultCredentials = true;
        req.Credentials       = CredentialCache.DefaultCredentials;

        try
        {
            req.CookieContainer = new CookieContainer();
            if (ctx != null && ctx.Request != null && ctx.Request.Cookies != null)
            {
                foreach (string key in ctx.Request.Cookies)
                {
                    var c = ctx.Request.Cookies[key];
                    if (c == null) continue;
                    try { req.CookieContainer.Add(new Uri(url), new Cookie(c.Name, c.Value, c.Path, c.Domain)); }
                    catch { }
                }
            }
        }
        catch { }

        using (var resp   = (HttpWebResponse)req.GetResponse())
        using (var stream = resp.GetResponseStream())
        {
            if (stream == null) return null;
            using (var sr = new StreamReader(stream, Encoding.UTF8))
                return sr.ReadToEnd();
        }
    }

    private static void WriteJson(HttpContext ctx, object obj)
    {
        var ser = new JavaScriptSerializer();
        ctx.Response.Write(ser.Serialize(obj));
    }

    public bool IsReusable { get { return true; } }
}
