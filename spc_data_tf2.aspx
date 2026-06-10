<%@ Page Language="C#" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>

<script runat="server">
  public class SpcRow {
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

  private static string GetConnStr() {
    ConnectionStringSettings cs = ConfigurationManager.ConnectionStrings["SpcDb"];
    if (cs != null && !string.IsNullOrWhiteSpace(cs.ConnectionString)) {
      return cs.ConnectionString;
    }
    string cs2 = ConfigurationManager.AppSettings["SpcDb"];
    if (!string.IsNullOrWhiteSpace(cs2)) {
      return cs2;
    }
    return "Server=UMCESIDB02;Database=GPTPoCDB;User ID=GPTPoCDBUser;Password=DB02.2026;TrustServerCertificate=True;";
  }

  private static string Safe(string s, int maxLen) {
    if (s == null) return "";
    s = s.Trim();
    if (s.Length > maxLen) s = s.Substring(0, maxLen);
    return s;
  }

  private void WriteJson(object obj) {
    JavaScriptSerializer serializer = new JavaScriptSerializer();
    serializer.MaxJsonLength = int.MaxValue;
    Response.Write(serializer.Serialize(obj));
  }

  protected void Page_Load(object sender, EventArgs e) {
    Response.ContentType = "application/json; charset=utf-8";

    string tab = Safe(Request["tab"], 30);
    tab = tab.ToUpperInvariant();

    string chartName = Safe(Request["chartName"], 200);
    if (chartName.Length == 0) chartName = "ALL";

    // mode: ADDER / PARTITION / UTHK
    string mode = "ADDER";
    if (tab == "PARTITION" || tab == "THK") {
      mode = "PARTITION";
    } else if (tab == "U" || tab == "U%" || tab == "UTHK" || tab == "THK-U" || tab == "THK_U") {
      mode = "UTHK";
    }

    string connStr = GetConnStr();
    if (string.IsNullOrWhiteSpace(connStr)) {
      Response.StatusCode = 500;
      WriteJson(new Dictionary<string, object> { { "error", "empty connection string" } });
      return;
    }

    try {
      List<SpcRow> rows = new List<SpcRow>();

      using (SqlConnection conn = new SqlConnection()) {
        conn.ConnectionString = connStr;
        conn.Open();

        using (SqlCommand cmd = conn.CreateCommand()) {
          cmd.CommandType = CommandType.Text;

          // mode=ADDER: PARAMETER='ADDER' AND RECIPE NOT LIKE 'PAR%'
          // mode=PARTITION: PARAMETER='ADDER' AND RECIPE LIKE 'PAR%'
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
      -- 分頁分類改依 CHART_NAME 關鍵字：LTPA / PAR_ 歸 Partition；其餘(含 -PA-)歸 ADDER
      -- 註：用 PAR[_] 比對字面底線，避免誤中結尾的「[Partition...]」
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

          using (SqlDataReader rdr = cmd.ExecuteReader()) {
            while (rdr.Read()) {
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
      return;

    } catch (Exception ex) {
      Response.StatusCode = 500;
      WriteJson(new Dictionary<string, object> { { "error", ex.Message } });
      return;
    }
  }
</script>
