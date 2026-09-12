<%@ WebHandler Language="C#" Class="EmstNote" %>

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;

// OCAP 明細的 EMST 填寫內容：一筆 OCAP（UCHART_ID + CHART_SEQ）一個 JSON 檔，存在本目錄下的 emst_data/。
//
//   GET  TF2api/EmstNote.ashx?uchart_id=85766&chart_seq=1832
//        → { ok:true, exists:true|false, note:{...}|null }
//   POST TF2api/EmstNote.ashx?uchart_id=85766&chart_seq=1832   body: JSON
//        body 欄位：chart_name, block, tool, waferCount, action, followUp
//        → { ok:true, note:{...} }（含 createdAt / updatedAt）
//
// 檔名只用數字組成，避免路徑穿越；寫檔加鎖，避免兩個人同時儲存互相覆蓋成半截檔。
// 根目錄 Web.config 的 hiddenSegments 已把 emst_data 擋掉，瀏覽器不能直接讀 JSON 檔。
public class EmstNote : IHttpHandler
{
    private const string DataFolder = "emst_data";
    private const int MaxTextLength = 4000;
    private static readonly object _lock = new object();

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json; charset=utf-8";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);

        try
        {
            string uchartId = Digits(context.Request["uchart_id"]);
            string chartSeq = Digits(context.Request["chart_seq"]);
            if (uchartId.Length == 0 || chartSeq.Length == 0)
            {
                WriteJson(context, 400, new Dictionary<string, object> { { "ok", false }, { "error", "uchart_id 與 chart_seq 必填" } });
                return;
            }

            string folder = context.Server.MapPath(DataFolder);
            string path = Path.Combine(folder, uchartId + "_" + chartSeq + ".json");

            if (string.Equals(context.Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase))
                Save(context, folder, path, uchartId, chartSeq);
            else
                Load(context, path);
        }
        catch (Exception ex)
        {
            WriteJson(context, 500, new Dictionary<string, object> { { "ok", false }, { "error", ex.Message } });
        }
    }

    private static void Load(HttpContext context, string path)
    {
        Dictionary<string, object> note = ReadNote(path);
        WriteJson(context, 200, new Dictionary<string, object> {
            { "ok", true },
            { "exists", note != null },
            { "note", note }
        });
    }

    private static void Save(HttpContext context, string folder, string path, string uchartId, string chartSeq)
    {
        string body;
        context.Request.InputStream.Position = 0;
        using (StreamReader sr = new StreamReader(context.Request.InputStream, Encoding.UTF8))
            body = sr.ReadToEnd();

        JavaScriptSerializer ser = new JavaScriptSerializer();
        Dictionary<string, object> incoming = string.IsNullOrEmpty(body)
            ? new Dictionary<string, object>()
            : ser.Deserialize<Dictionary<string, object>>(body) ?? new Dictionary<string, object>();

        string now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

        lock (_lock)
        {
            Directory.CreateDirectory(folder);
            Dictionary<string, object> existing = ReadNote(path);

            Dictionary<string, object> note = new Dictionary<string, object>();
            note["uchart_id"]  = uchartId;
            note["chart_seq"]  = chartSeq;
            note["chart_name"] = Text(incoming, "chart_name", 300);
            note["block"]      = Text(incoming, "block", 10);        // ADDER / NON-ADDER
            note["tool"]       = Text(incoming, "tool", 100);
            note["waferCount"] = Text(incoming, "waferCount", 500);
            note["action"]     = Text(incoming, "action", MaxTextLength);
            note["followUp"]   = Text(incoming, "followUp", MaxTextLength);
            note["createdAt"]  = existing != null && existing.ContainsKey("createdAt") ? existing["createdAt"] : now;
            note["updatedAt"]  = now;

            string json = new JavaScriptSerializer().Serialize(note);
            // 先寫暫存檔再改名，避免寫到一半被讀到殘缺內容
            string tmp = path + ".tmp";
            File.WriteAllText(tmp, json, new UTF8Encoding(false));
            if (File.Exists(path)) File.Delete(path);
            File.Move(tmp, path);

            WriteJson(context, 200, new Dictionary<string, object> { { "ok", true }, { "note", note } });
        }
    }

    private static Dictionary<string, object> ReadNote(string path)
    {
        if (!File.Exists(path)) return null;
        string json = File.ReadAllText(path, Encoding.UTF8);
        if (string.IsNullOrEmpty(json)) return null;
        return new JavaScriptSerializer().Deserialize<Dictionary<string, object>>(json);
    }

    // 只收字串，去前後空白並限制長度
    private static string Text(Dictionary<string, object> src, string key, int maxLength)
    {
        object v;
        if (!src.TryGetValue(key, out v) || v == null) return "";
        string s = Convert.ToString(v).Trim();
        return s.Length > maxLength ? s.Substring(0, maxLength) : s;
    }

    private static string Digits(string value)
    {
        if (value == null) return "";
        string s = Regex.Replace(value, "[^0-9]", "");
        return s.Length > 20 ? s.Substring(0, 20) : s;
    }

    private static void WriteJson(HttpContext context, int status, object payload)
    {
        context.Response.StatusCode = status;
        JavaScriptSerializer ser = new JavaScriptSerializer();
        ser.MaxJsonLength = int.MaxValue;
        context.Response.Write(ser.Serialize(payload));
    }

    public bool IsReusable { get { return true; } }
}
