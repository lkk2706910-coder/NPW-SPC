using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

// Shared DB query helper. Connection string comes from web.config
// ConnectionStrings["EMST"]. Use a 3-part name to reach
// GPTDB_USPC.dbo.TF2_NPW_CHART across databases.
//
// Usage:
//   var rows = DbHelper.QueryRows(
//       "SELECT TOP 10 * FROM GPTDB_USPC.dbo.TF2_NPW_CHART WHERE AREA = @p0", "TF2");
//
// NOTE: keep this file pure ASCII (some servers compile .cs as Big5/CP950).
public static class DbHelper
{
    private static string ConnStr()
    {
        ConnectionStringSettings cs = ConfigurationManager.ConnectionStrings["EMST"];
        if (cs != null && !string.IsNullOrWhiteSpace(cs.ConnectionString))
            return cs.ConnectionString;
        // Fallback if web.config has no entry.
        return "Server=UMCESIDB02;Database=GPTPoCDB;User ID=GPTPoCDBUser;Password=DB02.2026;TrustServerCertificate=True;";
    }

    // Parameters map to @p0, @p1, ... in order.
    public static List<Dictionary<string, object>> QueryRows(string sql, params object[] args)
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
