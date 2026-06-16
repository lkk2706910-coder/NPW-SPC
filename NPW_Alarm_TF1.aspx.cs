using System.Web.UI;

// TF1 variant of the NPW Alarm weekly report.
//
// All logic lives in NPW_Alarm. This subclass exists only so the TF1 markup
// has its own page class. The source table is chosen by NPW_Alarm.ChartTable
// from the request path: "NPW_Alarm_TF1.aspx" contains "TF1", so it reads
// GPTDB_USPC.dbo.TF1_NPW_CHART.
public partial class NPW_Alarm_TF1 : NPW_Alarm
{
}
