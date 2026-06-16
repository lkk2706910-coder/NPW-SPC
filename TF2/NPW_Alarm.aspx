<%@ Page Language="C#" AutoEventWireup="true" Inherits="NPW_Alarm" CodeFile="NPW_Alarm.aspx.cs" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>TF2 NPW Alarm 週報</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.3.0/dist/chart.umd.min.js"></script>
    <style>
        :root {
            color-scheme: dark;
            --bg-gradient: radial-gradient(1200px 600px at 20% 0%, #152a52 0%, #0b1220 60%);
            --panel: #0f1b33;
            --panel-elevated: #14233f;
            --text: #f3f7ff;
            --muted: #c6d0e6;
            --border: rgba(255,255,255,0.12);
            --tint-med: rgba(255,255,255,0.06);
            --tint-high: rgba(255,255,255,0.10);
            --row-hover: rgba(99,179,237,0.10);
            --chip: rgba(99,179,237,0.18);
            --chip-active-bg: rgba(99,179,237,0.22);
            --chip-active-border: rgba(99,179,237,0.55);
            --accent: #63b3ed;
            --accent-strong: #2563eb;
            --input-bg: rgba(5,10,20,0.30);
            --warn: #fbbf24;
            --warn-bg: rgba(251,191,36,0.10);
            --warn-border: rgba(251,191,36,0.40);
            --danger: #fca5a5;
        }
        * { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Noto Sans TC", Arial, sans-serif;
            background: #fff;
            color: #111;
            min-height: 100vh;
        }
        .topbar {
            display: flex; align-items: center;
            padding: 12px 22px;
            background: #fff;
            color: #111;
            border-bottom: 1px solid #ddd;
            gap: 14px;
        }
        .topbar h1 { font-size: 16px; margin: 0; }
        .seg-tabs { display: flex; gap: 8px; margin-left: auto; }
        .seg-btn { padding: 6px 16px; border: 1px solid #1976d2; border-radius: 6px; background: #fff; color: #1976d2; cursor: pointer; font-size: 14px; font-weight: 600; }
        .seg-btn:hover { background: #eef4ff; }
        .seg-btn.active { background: #1976d2; color: #fff; }
        .down-sum { border-collapse: collapse; font-size: 13px; color: #111; }
        .down-sum td, .down-sum th { border: 1px solid #333; padding: 4px 12px; text-align: center; }
        .down-sum .ds-title { background: #ffff66; font-weight: 700; }
        .down-sum .ds-h { background: #fff; font-weight: 700; white-space: nowrap; }
        .down-sum .ds-corner { background: #bcd6ee; }
        .down-sum .ds-rowh { background: #bcd6ee; font-weight: 700; }
        .down-sum .ds-v { background: #fff; }
        .dc-toolbar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; margin: 4px 0 14px; }
        .dc-toolbar button { padding: 6px 14px; border: 0; border-radius: 6px; background: #1976d2; color: #fff; cursor: pointer; }
        .dc-toolbar input[type="date"] { padding: 6px 8px; border: 1px solid #999; border-radius: 4px; background: #fff; color: #111; font-size: 14px; }
        .sched-title { font-weight: 700; color: #c00; margin: 12px 0 4px; }
        .sched-scroll { overflow-x: auto; margin-bottom: 16px; }
        .sched { border-collapse: collapse; font-size: 12px; color: #111; background: #fff; }
        .sched th, .sched td { border: 1px solid #333; padding: 3px 6px; text-align: center; vertical-align: middle; min-width: 66px; white-space: nowrap; }
        .sched th { background: #f0f0f0; }
        .sched .sched-ent { background: #fff; text-align: left; font-weight: 700; white-space: nowrap; position: sticky; left: 0; z-index: 1; }
        .wrap { max-width: none; margin: 0 auto; padding: 24px 18px; }
        .card {
            background: var(--panel);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 18px 20px;
            margin-bottom: 18px;
        }
        .card h2 { font-size: 16px; margin: 0 0 8px; }
        .card p { color: var(--muted); line-height: 1.6; margin: 0 0 6px; }
        code { background: var(--tint-med); padding: 2px 6px; border-radius: 4px; font-size: 13px; }

        /* =============================================================
           AI chat widget styles -- self-contained, can be removed
           if you don't need the embedded chat.
           ============================================================= */
        .img-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.85); z-index: 9999; display: flex; align-items: center; justify-content: center; cursor: zoom-out; }
        .img-overlay img { border-radius: 6px; }
        #aiBubble {
            position: fixed; right: 22px; bottom: 22px;
            width: 56px; height: 56px; border-radius: 50%; border: none; cursor: pointer;
            background: linear-gradient(135deg, var(--accent) 0%, var(--accent-strong) 100%);
            color: #fff; font-weight: 700; font-size: 16px; letter-spacing: 0.5px;
            box-shadow: 0 8px 24px rgba(37, 99, 235, 0.45), 0 2px 6px rgba(0,0,0,0.25);
            z-index: 9999; transition: transform .15s ease;
        }
        #aiBubble:hover { transform: translateY(-2px); }
        #aiBubble.open { transform: scale(0.9); }
        #aiPanel {
            position: fixed; right: 22px; bottom: 90px;
            width: 800px; height: 760px;
            max-width: calc(100vw - 44px); max-height: calc(100vh - 120px);
            background: var(--panel); border: 1px solid var(--border); border-radius: 14px;
            color: var(--text);
            box-shadow: 0 20px 50px rgba(0,0,0,0.45);
            display: flex; flex-direction: row; overflow: hidden; z-index: 9999;
        }
        #aiPanel[hidden] { display: none; }
        .ai-sidebar { width: 160px; flex: none; display: flex; flex-direction: column; background: var(--panel-elevated); border-right: 1px solid var(--border); }
        .ai-new-btn { margin: 8px; padding: 6px 10px; border-radius: 8px; background: var(--accent); color: #fff; border: none; cursor: pointer; font-size: 13px; font-weight: 600; }
        .ai-new-btn:hover { background: var(--accent-strong); }
        .ai-sess-list { flex: 1; overflow-y: auto; padding: 0 6px 6px; display: flex; flex-direction: column; gap: 3px; }
        .ai-sess { position: relative; padding: 6px 8px; border-radius: 8px; cursor: pointer; border: 1px solid transparent; }
        .ai-sess:hover { background: var(--row-hover); }
        .ai-sess.active { background: var(--tint-high); border-color: var(--chip-active-border); }
        .ai-sess-title { font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; padding-right: 16px; }
        .ai-sess-del { position: absolute; top: 4px; right: 4px; background: transparent; border: none; color: var(--muted); cursor: pointer; font-size: 14px; line-height: 1; padding: 0 4px; border-radius: 4px; opacity: 0; transition: opacity .12s; }
        .ai-sess:hover .ai-sess-del, .ai-sess.active .ai-sess-del { opacity: 1; }
        .ai-sess-del:hover { background: var(--warn-bg); color: var(--danger); }
        .ai-main { flex: 1; display: flex; flex-direction: column; overflow: hidden; min-width: 0; }
        .ai-head {
            display: flex; align-items: center; justify-content: space-between;
            padding: 10px 14px;
            background: linear-gradient(135deg, rgba(99,179,237,0.15), rgba(37,99,235,0.10));
            border-bottom: 1px solid var(--border);
        }
        .ai-title-input { flex: 1; min-width: 0; background: transparent; border: 1px solid transparent; color: var(--text); font-weight: 600; font-size: 14px; outline: none; padding: 4px 8px; border-radius: 6px; }
        .ai-title-input:focus { background: var(--tint-med); border-color: var(--accent); }
        #aiClose { background: transparent; border: none; color: var(--muted); font-size: 22px; line-height: 1; cursor: pointer; padding: 2px 6px; border-radius: 6px; }
        #aiClose:hover { background: var(--tint-med); color: var(--text); }
        .ai-msgs { flex: 1; overflow-y: auto; padding: 14px; display: flex; flex-direction: column; gap: 10px; }
        .ai-msg { max-width: 86%; padding: 8px 12px; border-radius: 12px; font-size: 13px; line-height: 1.5; white-space: pre-wrap; word-wrap: break-word; }
        .ai-msg.user { align-self: flex-end; background: var(--accent-strong); color: #fff; border-bottom-right-radius: 4px; }
        .ai-msg.assistant { align-self: flex-start; background: var(--tint-med); border-bottom-left-radius: 4px; }
        .ai-msg.error { align-self: stretch; background: var(--warn-bg); border: 1px solid var(--warn-border); color: var(--warn); font-size: 12px; }
        .ai-msg.typing { align-self: flex-start; background: var(--tint-med); color: var(--muted); }
        .ai-msg.typing .dot { display: inline-block; width: 6px; height: 6px; border-radius: 50%; background: var(--muted); margin: 0 2px; animation: ai-blink 1.2s infinite; }
        .ai-msg.typing .dot:nth-child(2) { animation-delay: .2s; }
        .ai-msg.typing .dot:nth-child(3) { animation-delay: .4s; }
        @keyframes ai-blink { 0%, 80%, 100% { opacity: 0.25; } 40% { opacity: 1; } }
        .ai-msg-img { margin-top: 6px; max-width: 220px; max-height: 160px; border-radius: 8px; display: block; cursor: zoom-in; }
        .ai-input-wrap { border-top: 1px solid var(--border); padding: 10px; display: flex; gap: 8px; background: var(--panel-elevated); }
        .ai-icon-btn { background: var(--tint-med); border: 1px solid var(--border); color: var(--text); border-radius: 8px; width: 38px; height: 38px; display: inline-flex; align-items: center; justify-content: center; cursor: pointer; flex: none; }
        .ai-icon-btn:hover { background: var(--tint-high); border-color: var(--accent); }
        .ai-preview { display: flex; align-items: center; gap: 8px; padding: 8px 10px; background: var(--panel-elevated); border-top: 1px solid var(--border); }
        .ai-preview[hidden] { display: none; }
        .ai-preview img { max-height: 56px; max-width: 90px; border-radius: 6px; border: 1px solid var(--border); object-fit: contain; background: #000; cursor: zoom-in; }
        .ai-preview .ai-prev-meta { color: var(--muted); font-size: 12px; flex: 1; }
        .ai-preview .ai-prev-remove { background: var(--tint-med); border: 1px solid var(--border); color: var(--text); border-radius: 6px; padding: 4px 10px; cursor: pointer; font-size: 12px; }
        #aiInput { flex: 1; min-height: 38px; max-height: 120px; resize: none; padding: 8px 10px; border-radius: 8px; border: 1px solid var(--border); background: var(--input-bg); color: var(--text); font-family: inherit; font-size: 13px; outline: none; }
        #aiInput:focus { border-color: var(--accent); }
        #aiSend { white-space: nowrap; padding: 8px 16px; border-radius: 8px; background: var(--accent); color: #fff; border: 1px solid var(--accent); cursor: pointer; font-weight: 600; }
        #aiSend:hover { background: var(--accent-strong); }
        #aiSend:disabled { opacity: 0.5; cursor: not-allowed; }
    </style>
</head>
<body>
    <div class="topbar">
        <h1>TF2 NPW</h1>
        <div class="seg-tabs">
            <button type="button" class="seg-btn active" data-sec="weekly">NPW Alarm 週報</button>
            <button type="button" class="seg-btn" data-sec="downchart">down chart 作業區</button>
        </div>
    </div>

    <div class="wrap">
        <style>
        .npw-report-card{background:transparent;color:#111;border:0;border-radius:0;padding:0;margin:0;box-shadow:none;}
        .npw-report-card h2{color:#111;}
        .npw-report-card .npw-toolbar{display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin:0 0 12px;}
        .npw-report-card .npw-toolbar label{font-weight:700;}
        .npw-report-card input[type="date"]{padding:6px 8px;border:1px solid #999;border-radius:4px;background:#fff;color:#111;font-size:14px;}
        .npw-report-card .npw-date-wrap{display:inline-flex;align-items:center;gap:4px;}
        .npw-report-card #calBtn{display:inline-flex;align-items:center;justify-content:center;width:32px;height:32px;padding:0;border:1px solid #999;border-radius:4px;background:#fff;color:#1976d2;cursor:pointer;}
        .npw-report-card #calBtn:hover{background:#eef4ff;border-color:#1976d2;}
        .npw-report-card #reloadBtn{padding:6px 14px;border:0;border-radius:6px;background:#1976d2;color:#fff;cursor:pointer;}
        .npw-report-card .npw-week-hint{color:#0f4aa8;font-weight:700;}
        .npw-report-card .npw-status{color:#555;font-size:12px;}
        .npw-report-card .npw-error{color:#c00;font-size:12px;white-space:pre-line;margin-bottom:8px;}
        .npw-report-card .report-scroll{overflow:auto;}
        .npw-report-card .report{width:100%;border-collapse:collapse;table-layout:fixed;background:#fff;border:2px solid #222;margin:0 0 18px;}
        .npw-report-card .report th,.npw-report-card .report td{border:1px solid #222;font-size:12px;padding:4px 6px;line-height:1.2;text-align:center;vertical-align:middle;color:#111;}
        .npw-report-card .section-title{background:#b7d2ea;font-weight:700;text-align:left;padding:6px 10px!important;border-bottom:2px solid #222!important;}
        .npw-report-card .h-green{background:#d9f2c2;font-weight:700;}
        .npw-report-card .h-amber{background:#ffe19a;font-weight:700;}
        .npw-report-card .left{text-align:left;}
        .npw-report-card .barcell{position:relative;overflow:hidden;}
        .npw-report-card .barcell .bar{position:absolute;left:0;top:3px;bottom:3px;width:var(--w,0%);background:linear-gradient(to right,#ff6b6b,#ffd1d1);}
        .npw-report-card .barcell .txt{position:relative;z-index:1;font-weight:700;}
        .npw-report-card tfoot td{font-weight:700;}
        .npw-report-card .total-label{text-align:right;background:#f4f4f4;}
        .npw-report-card .total-good{background:#cfe8b6;}
        .npw-report-card .total-warn{background:#fff0b3;}
        .npw-report-card col.entity{width:92px;}
        .npw-report-card col.date{width:74px;}
        .npw-report-card col.statS{width:72px;}
        .npw-report-card col.statM{width:92px;}
        .npw-report-card .alarm-over-target{background-color:#ffd1e6!important;}
        .npw-report-card .total-green-over-yellow{background-color:#ffd1e6!important;}
        .npw-report-card #adderChartDetail,.npw-report-card #nonAdderChartDetail{overflow-x:auto;}
        .npw-report-card .chart-detail{width:100%;border-collapse:collapse;background:#fff;border:2px solid #222;margin:-6px 0 18px;}
        .npw-report-card .chart-detail th,.npw-report-card .chart-detail td{border:1px solid #222;font-size:12px;padding:4px 6px;line-height:1.2;vertical-align:middle;color:#111;text-align:left;word-break:break-all;}
        .npw-report-card .chart-detail th{background:#f5f5f5;font-weight:700;white-space:nowrap;}
        .npw-report-card .chart-detail .cn-col{min-width:260px;white-space:normal;word-break:break-word;}
        .npw-report-card .chart-detail a{color:#1d4ed8;}
        .npw-report-card .npw-mini-btn{font-size:11px;padding:2px 6px;border:1px solid #1976d2;border-radius:4px;background:#fff;color:#1976d2;cursor:pointer;}
        .npw-report-card .npw-mini-btn:hover{background:#1976d2;color:#fff;}
        .npw-report-card .npw-cell-preview{padding:2px!important;}
        .npw-report-card .npw-spark{position:relative;width:372px;height:208px;}
        .npw-report-card .npw-spark canvas{display:block;width:100%!important;height:100%!important;}
        .npw-report-card .npw-cell-map{text-align:center;padding:2px!important;}
        .npw-report-card .adder-map-thumb{width:184px;max-width:184px;height:auto;border:1px solid #bbb;background:#fafafa;object-fit:contain;display:block;margin:0 auto;cursor:zoom-in;}
        .npw-report-card .dup-chart{background:#ffe19a!important;}
        .npw-report-card .dim-row{background:#d9d9d9!important;}
        .npw-report-card .inline-empty{padding:8px 10px;color:#666;font-size:12px;background:#fff;border:1px dashed #999;}
        </style>
        <section id="sec-weekly">
        <div class="card npw-report-card">
            <div class="npw-toolbar">
                <h2 style="margin:0;">NPW Alarm 週報</h2>
                <label for="pickDate">選擇日期</label>
                <span class="npw-date-wrap">
                    <input id="pickDate" type="date" />
                    <button id="calBtn" type="button" title="開啟日期選擇器" aria-label="開啟日期選擇器">
                        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                            <line x1="16" y1="2" x2="16" y2="6"></line>
                            <line x1="8" y1="2" x2="8" y2="6"></line>
                            <line x1="3" y1="10" x2="21" y2="10"></line>
                        </svg>
                    </button>
                </span>
                <span class="npw-week-hint" id="weekHint"></span>
                <button id="reloadBtn" type="button">重新整理</button>
                <span id="status" class="npw-status">資料載入中...</span>
            </div>
            <div id="error" class="npw-error" style="display:none;"></div>

            <!-- ========== ADDER ========== -->
            <div class="report-scroll">
            <table class="report" id="tblAdder">
                <colgroup>
                    <col class="entity">
                    <col class="date"><col class="date"><col class="date"><col class="date"><col class="date"><col class="date"><col class="date">
                    <col class="statS"><col class="statM"><col class="statS"><col class="statS">
                    <col class="statS"><col class="statS"><col class="statM">
                </colgroup>
                <thead>
                    <tr><th class="section-title" colspan="15">ADDER</th></tr>
                    <tr>
                        <th class="h-green">Entity</th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-amber">Alarm<br/>Counts</th>
                        <th class="h-amber">Over Weekly to<br/>Day Count</th>
                        <th class="h-amber">Weekly to<br/>Day Target</th>
                        <th class="h-amber">Weekly<br/>Target Count</th>
                        <th class="h-amber">Alarm<br/>rate</th>
                        <th class="h-amber">Weekly<br/>Target Rate</th>
                        <th class="h-amber">Total Monitor<br/>Count</th>
                    </tr>
                </thead>
                <tbody>
                    <tr data-entity="NISACVD">
                        <td class="left entity-cell">NISACVD</td>
                        <td></td><td></td><td></td><td></td><td></td><td></td><td></td>
                        <td>0</td>
                        <td class="barcell"><span class="bar"></span><span class="txt">0</span></td>
                        <td>0</td><td>0</td>
                        <td>0%</td><td>0%</td><td>0</td>
                    </tr>
                    <tr data-entity="SACVD">
                        <td class="left entity-cell">SACVD</td>
                        <td></td><td></td><td></td><td></td><td></td><td></td><td></td>
                        <td>0</td>
                        <td class="barcell"><span class="bar"></span><span class="txt">0</span></td>
                        <td>0</td><td>0</td>
                        <td>0%</td><td>0%</td><td>0</td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td class="total-label" colspan="8">Total Alarm</td>
                        <td id="adderTotalAlarm">0</td>
                        <td class="total-good" colspan="2" id="adderTotalAlarmRate">0%</td>
                        <td></td><td></td>
                        <td class="total-warn" colspan="2" id="adderTotalWeeklyTargetRate">0%</td>
                    </tr>
                </tfoot>
            </table>
            </div>
            <div id="adderChartDetail"></div>

            <!-- ========== NON-ADDER ========== -->
            <div class="report-scroll">
            <table class="report" id="tblNonAdder">
                <colgroup>
                    <col class="entity">
                    <col class="date"><col class="date"><col class="date"><col class="date"><col class="date"><col class="date"><col class="date">
                    <col class="statS"><col class="statM"><col class="statS"><col class="statS">
                    <col class="statS"><col class="statS"><col class="statM">
                </colgroup>
                <thead>
                    <tr><th class="section-title" colspan="15">NON-ADDER</th></tr>
                    <tr>
                        <th class="h-green">Entity</th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-green date-head"></th>
                        <th class="h-amber">Alarm<br/>Counts</th>
                        <th class="h-amber">Over Weekly to<br/>Day Count</th>
                        <th class="h-amber">Weekly to<br/>Day Target</th>
                        <th class="h-amber">Weekly<br/>Target Count</th>
                        <th class="h-amber">Alarm<br/>rate</th>
                        <th class="h-amber">Weekly<br/>Target Rate</th>
                        <th class="h-amber">Total Monitor<br/>Count</th>
                    </tr>
                </thead>
                <tbody>
                    <tr data-entity="NISACVD">
                        <td class="left entity-cell">NISACVD</td>
                        <td></td><td></td><td></td><td></td><td></td><td></td><td></td>
                        <td>0</td>
                        <td class="barcell"><span class="bar"></span><span class="txt">0</span></td>
                        <td>0</td><td>0</td>
                        <td>0%</td><td>0%</td><td>0</td>
                    </tr>
                    <tr data-entity="SACVD">
                        <td class="left entity-cell">SACVD</td>
                        <td></td><td></td><td></td><td></td><td></td><td></td><td></td>
                        <td>0</td>
                        <td class="barcell"><span class="bar"></span><span class="txt">0</span></td>
                        <td>0</td><td>0</td>
                        <td>0%</td><td>0%</td><td>0</td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td class="total-label" colspan="8">Total Alarm</td>
                        <td id="nonAdderTotalAlarm">0</td>
                        <td class="total-good" colspan="2" id="nonAdderTotalAlarmRate">0%</td>
                        <td></td><td></td>
                        <td class="total-warn" colspan="2" id="nonAdderTotalWeeklyTargetRate">0%</td>
                    </tr>
                </tfoot>
            </table>
            </div>
            <div id="nonAdderChartDetail"></div>
        </div>
        </section>

        <section id="sec-downchart" hidden>
            <div class="dc-toolbar">
                <button id="dcPrev" type="button">◀ 上週</button>
                <input id="dcDate" type="date" />
                <button id="dcNext" type="button">下週 ▶</button>
                <span id="dcWeek" class="npw-week-hint"></span>
            </div>
            <div id="downAdderSummary" style="display:flex;gap:24px;flex-wrap:wrap;margin:8px 0 16px;"></div>
            <div id="downSchedule"></div>
        </section>
    </div>

    <script>
    // 上方區塊切換：NPW Alarm 週報 / down chart 作業區
    (function(){
        const btns=[...document.querySelectorAll('.seg-btn')];
        const secs={weekly:document.getElementById('sec-weekly'),downchart:document.getElementById('sec-downchart')};
        function show(name){
            for(const k in secs){if(secs[k])secs[k].hidden=(k!==name);}
            btns.forEach(b=>b.classList.toggle('active',b.getAttribute('data-sec')===name));
        }
        btns.forEach(b=>b.addEventListener('click',()=>show(b.getAttribute('data-sec'))));
    })();
    </script>

    <script>
    // NPW Alarm 週報：沿用原工具(TF2_NPW.html)的判讀邏輯，資料來源改為
    // NPW_Alarm.aspx?op=alarm（DB: GPTDB_USPC.dbo.TF2_NPW_CHART）。
    (function () {
        // 自我參照目前頁面（NPW_Alarm.aspx 或 NPW_Alarm_TF1.aspx），讓 TF1/TF2 各自打自己的後端
        const PAGE = location.pathname.split('/').pop() || 'NPW_Alarm.aspx';
        // ===== 日期工具 =====
        function toISODateLocal(d){const y=d.getFullYear(),m=String(d.getMonth()+1).padStart(2,'0'),dd=String(d.getDate()).padStart(2,'0');return `${y}-${m}-${dd}`;}
        function fmtYMD(d){const y=d.getFullYear(),m=String(d.getMonth()+1).padStart(2,'0'),dd=String(d.getDate()).padStart(2,'0');return `${y}/${m}/${dd}`;}
        function fmtYMDDash(d){const y=d.getFullYear(),m=String(d.getMonth()+1).padStart(2,'0'),dd=String(d.getDate()).padStart(2,'0');return `${y}-${m}-${dd}`;}
        // 以「選擇日往前的禮拜二」為第一天
        function startTuesdayFor(sel){const d=new Date(sel.getFullYear(),sel.getMonth(),sel.getDate());const diff=((d.getDay()-2)+7)%7;d.setDate(d.getDate()-diff);return d;}
        function getWeekNumber(d){const date=new Date(d.getFullYear(),d.getMonth(),d.getDate());const dayNr=(date.getDay()+6)%7;date.setDate(date.getDate()-dayNr+3);const ft=new Date(date.getFullYear(),0,4);const fd=(ft.getDay()+6)%7;ft.setDate(ft.getDate()-fd+3);return 1+Math.round((date-ft)/(7*24*3600*1000));}

        function setHeadersByPickedDate(picked){
            const start=startTuesdayFor(picked);
            const a=document.querySelectorAll('#tblAdder .date-head');
            const n=document.querySelectorAll('#tblNonAdder .date-head');
            for(let i=0;i<7;i++){const d=new Date(start.getFullYear(),start.getMonth(),start.getDate());d.setDate(start.getDate()+i);const t=fmtYMD(d);if(a[i])a[i].textContent=t;if(n[i])n[i].textContent=t;}
        }

        // ===== 目標設定（沿用原工具給定值）=====
        const WEEKLY_TARGET_ADDER={NISACVD:6,ULKCVD:6,SACVD:7,TEOSPE:10,CUSILPE:5,BLOKCVD:5,DARC:1,OXSE:1,APF:1,TTOX:0,ALDOX:0,HKG:2,CUTTOX:1,SILPE:0,CULKCVD:0};
        const WEEKLY_TARGET_NON_ADDER={CUSILPE:19,ULKCVD:20,TEOSPE:17,SACVD:14,NISACVD:17,OXSE:2,HKG:3,TTOX:2,DARC:5,SILPE:1,BLOKCVD:2,APF:5,CUTTOX:3,CUKVALUE:0,CULKCVD:1,ALDOX:1};
        function getWeeklyTargetCount(e,isAdder){const t=isAdder?WEEKLY_TARGET_ADDER:WEEKLY_TARGET_NON_ADDER;return t[e]!=null?t[e]:0;}
        const WEEKLY_TARGET_RATE_ADDER={ULKCVD:1.49,TEOSPE:1.26,SACVD:1.35,BLOKCVD:1.95,CUSILPE:1.09,CUTTOX:0.52,NISACVD:1.17,HKG:1.46,DARC:1.84,SILPE:2.10,APF:0.62,OXSE:2.22,TTOX:0.68,CULKCVD:0.00};
        const WEEKLY_TARGET_RATE_NON_ADDER={TEOSPE:0.90,SACVD:0.60,ULKCVD:0.90,CUSILPE:0.60,HKG:0.60,NISACVD:0.60,TTOX:0.60,SILPE:0.60,DARC:0.60,BLOKCVD:0.60,CUTTOX:0.60,APF:0.60,OXSE:0.60,CULKCVD:0.60,CUKVALUE:0.60,ALDOX:0.60};
        function getWeeklyTargetRate(e,isAdder){const t=isAdder?WEEKLY_TARGET_RATE_ADDER:WEEKLY_TARGET_RATE_NON_ADDER;return t[e]!=null?t[e]:0;}

        // ===== 狀態 =====
        let rawData=[];
        let chartAlarmStats={};
        let chartAlarmDateStats={};
        let chartMeasurePu={}; // key|chartKey -> MEASUREPU
        let chartAlarmSeq={};  // key|chartKey -> Set(CHART_SEQ)
        let chartProcUnit={};  // key|chartKey -> PROCESSUNIT
        let chartAlarmMean={}; // key|chartKey -> MEAN_VALUE (代表 alarm 點，與 CHART_SEQ 同一筆)
        let chartAlarmWafer={};// key|chartKey -> WAFER (同一筆代表 alarm 點)
        let chartParameter={}; // key|chartKey -> PARAMETER (profile myParaList 用)
        function setStatus(t,c){const s=document.getElementById('status');s.textContent=t||'';if(c)s.style.color=c;}
        function showError(t){const e=document.getElementById('error');e.textContent=t||'';e.style.display=t?'block':'none';}

        // ===== 從 DB 載入該週原始資料 =====
        async function loadFromDb(picked){
            showError('');
            setStatus('資料載入中...','#555');
            try{
                const qs=new URLSearchParams({op:'alarm'});
                if(picked)qs.set('date',toISODateLocal(picked));
                const res=await fetch(PAGE+'?'+qs.toString(),{cache:'no-store'});
                const data=await res.json();
                if(!data.ok)throw new Error(data.error||('HTTP '+res.status));
                rawData=data.rows||[];
                setStatus('資料載入完成（'+(data.week?data.week.label:'')+'　'+rawData.length+' 筆）','#006400');
            }catch(err){
                console.error(err);
                setStatus('','');
                showError('讀取資料發生錯誤：\n'+err.message);
                rawData=[];
                throw err;
            }
        }

        // ===== 統計（沿用原工具，欄位改為 DB）=====
        function buildStats(picked){
            const start=startTuesdayFor(picked);
            const days=[];
            for(let i=0;i<7;i++){const d=new Date(start.getFullYear(),start.getMonth(),start.getDate());d.setDate(start.getDate()+i);days.push(fmtYMDDash(d));}
            const stats={};
            chartAlarmStats={};chartAlarmDateStats={};chartMeasurePu={};chartAlarmSeq={};chartProcUnit={};chartAlarmMean={};chartAlarmWafer={};chartParameter={};
            function entOf(pu){if(!pu)return null;const s=String(pu).toUpperCase();const i=s.indexOf('-');return i===-1?s:s.substring(0,i);}

            for(const row of rawData){
                const entity=entOf(row.PROCESSUNIT);
                if(!entity)continue;

                let ut=row.UPDATE_TIME;
                if(!ut)continue;
                if(typeof ut==='string'){ut=ut.substring(0,10);}
                else{const j=new Date(ut);if(isNaN(j.getTime()))continue;ut=fmtYMDDash(j);}
                if(!days.includes(ut))continue;

                const MT=String(row.MONITOR_TYPE||'').toUpperCase();
                const CT=String(row.CHART_TYPE||'').trim().toUpperCase();
                const CN=row.CHART_NAME||'';
                const CID=row.CHART_ID||'';
                const isEng=String(row.CHART_DESC||'').trim().toUpperCase()==='ENGINEERING';
                const alarmCnt=Number(row.ALARM_COUNT)||0;

                if(!stats[entity])stats[entity]={daily:{},sum:{alarmAdder:0,alarmNonAdder:0,totalMonAdder:0,totalMonNonAdder:0}};
                const es=stats[entity];
                if(!es.daily[ut])es.daily[ut]={alarmAdder:0,alarmNonAdder:0,totalMonAdder:0,totalMonNonAdder:0};
                const ds=es.daily[ut];

                const MON=1; // DB 無 MON_CNT，一列算 1（同原工具預設）

                // Total Monitor Count（MONITOR_TYPE=NORMAL 且非 Engineering）
                if(MT==='NORMAL'&&!isEng){
                    if(CT==='C-C'){ds.totalMonAdder+=MON;es.sum.totalMonAdder+=MON;}
                    else if(CT==='XBAR'){ds.totalMonNonAdder+=MON;es.sum.totalMonNonAdder+=MON;}
                }

                // Alarm 條件
                if(MT!=='NORMAL')continue;
                if(!(alarmCnt>=1))continue;
                if(isEng)continue;

                let isAdder;
                if(CT==='C-C'){isAdder=true;ds.alarmAdder+=1;es.sum.alarmAdder+=1;}
                else if(CT==='XBAR'){isAdder=false;ds.alarmNonAdder+=1;es.sum.alarmNonAdder+=1;}
                else continue;

                // Chart 層級 alarm 統計
                const key=fmtYMDDash(start)+'|'+entity+'|'+(isAdder?'ADDER':'NON_ADDER');
                if(!chartAlarmStats[key])chartAlarmStats[key]={};
                const ck=CID+'||'+CN;
                chartAlarmStats[key][ck]=(chartAlarmStats[key][ck]||0)+1;
                if(!chartAlarmDateStats[key])chartAlarmDateStats[key]={};
                if(!chartAlarmDateStats[key][ck])chartAlarmDateStats[key][ck]=new Set();
                chartAlarmDateStats[key][ck].add(ut);
                if(row.MEASUREPU!=null&&String(row.MEASUREPU).trim()!=='')chartMeasurePu[key+'|'+ck]=String(row.MEASUREPU);
                if(row.PROCESSUNIT!=null)chartProcUnit[key+'|'+ck]=String(row.PROCESSUNIT);
                if(row.PARAMETER!=null&&String(row.PARAMETER).trim()!==''&&chartParameter[key+'|'+ck]==null)chartParameter[key+'|'+ck]=String(row.PARAMETER);
                if(row.CHART_SEQ!=null&&String(row.CHART_SEQ).trim()!==''){
                    const sk=key+'|'+ck;
                    if(!chartAlarmSeq[sk]){chartAlarmSeq[sk]=new Set();if(chartAlarmMean[sk]==null&&row.MEAN_VALUE!=null)chartAlarmMean[sk]=row.MEAN_VALUE;if(chartAlarmWafer[sk]==null&&row.WAFER!=null)chartAlarmWafer[sk]=row.WAFER;}
                    chartAlarmSeq[sk].add(String(row.CHART_SEQ).trim());
                }
            }
            return {stats,days};
        }

        function updateTableByStats(tableId,stats,days,isAdder,picked){
            const tbl=document.getElementById(tableId);
            const tbody=tbl.querySelector('tbody');
            const rows=tbody.querySelectorAll('tr[data-entity]');

            let totalAlarmAll=0,totalMonitorAll=0;

            const start=startTuesdayFor(picked);
            const pm=new Date(picked);pm.setHours(0,0,0,0);
            const sm=new Date(start);sm.setHours(0,0,0,0);
            const dayIndex=Math.floor((pm-sm)/(24*3600*1000));
            const dayOfRange=Math.min(Math.max(dayIndex+1,1),7);

            rows.forEach(row=>{
                const entity=row.getAttribute('data-entity');
                const es=stats[entity]||null;

                const dateTds=Array.from(row.querySelectorAll('td')).slice(1,8);
                let alarmCount=0;
                for(let i=0;i<7;i++){
                    const dayStr=days[i];
                    let value='';
                    if(es&&es.daily[dayStr]){const ds=es.daily[dayStr];value=isAdder?(ds.alarmAdder||''):(ds.alarmNonAdder||'');}
                    dateTds[i].textContent=value?String(value):'';
                }

                let totalMonitor=0;
                if(es){
                    if(isAdder){alarmCount=es.sum.alarmAdder||0;totalMonitor=es.sum.totalMonAdder||0;}
                    else{alarmCount=es.sum.alarmNonAdder||0;totalMonitor=es.sum.totalMonNonAdder||0;}
                }

                const tds=row.querySelectorAll('td');

                // Alarm Counts (第 9 欄)
                const alarmTd=tds[8];
                alarmTd.textContent=alarmCount?String(alarmCount):'0';

                // Weekly Target Count
                const weeklyTargetCount=getWeeklyTargetCount(entity,isAdder);
                // Weekly to Day Target = Weekly Target Count * (今天是第幾天 / 7)
                let weeklyToDayTarget=0;
                if(dayOfRange>0)weeklyToDayTarget=Math.round(weeklyTargetCount*(dayOfRange/7));

                // Over Weekly to Day Count (第 10 欄, barcell)
                const overTd=tds[9];
                const txt=overTd.querySelector('.txt');
                const overCount=Math.max(0,alarmCount-weeklyToDayTarget);
                txt.textContent=overCount?String(overCount):'0';
                let widthPercent=0;
                if(overCount>0)widthPercent=Math.min(100,overCount*10);
                overTd.style.setProperty('--w',widthPercent+'%');

                // Weekly to Day Target (第 11 欄) & Weekly Target Count (第 12 欄)
                tds[10].textContent=weeklyToDayTarget?String(weeklyToDayTarget):'0';
                tds[11].textContent=weeklyTargetCount?String(weeklyTargetCount):'0';

                // Alarm rate (第 13 欄)
                let alarmRate=0;
                if(totalMonitor>0)alarmRate=alarmCount/totalMonitor;
                tds[12].textContent=(alarmRate*100).toFixed(2)+'%';

                // Weekly Target Rate (第 14 欄)
                tds[13].textContent=getWeeklyTargetRate(entity,isAdder).toFixed(2)+'%';

                // Total Monitor Count (第 15 欄)
                tds[14].textContent=totalMonitor?String(totalMonitor):'0';

                // Alarm Counts > Weekly Target Count 粉紅標記
                if(alarmCount>weeklyTargetCount)alarmTd.classList.add('alarm-over-target');
                else alarmTd.classList.remove('alarm-over-target');

                totalAlarmAll+=alarmCount;totalMonitorAll+=totalMonitor;
            });

            // 表尾
            if(isAdder){
                document.getElementById('adderTotalAlarm').textContent=String(totalAlarmAll);
                document.getElementById('adderTotalAlarmRate').textContent=totalMonitorAll>0?(totalAlarmAll/totalMonitorAll*100).toFixed(2)+'%':'0%';
                document.getElementById('adderTotalWeeklyTargetRate').textContent='1.48%';
            }else{
                document.getElementById('nonAdderTotalAlarm').textContent=String(totalAlarmAll);
                document.getElementById('nonAdderTotalAlarmRate').textContent=totalMonitorAll>0?(totalAlarmAll/totalMonitorAll*100).toFixed(2)+'%':'0%';
                document.getElementById('nonAdderTotalWeeklyTargetRate').textContent='0.75%';
            }

            // 綠色(Total Alarm rate) > 黃色(Total Weekly Target Rate) 時綠色變粉紅
            const tf=tbl.querySelector('tfoot tr');
            if(tf){
                const cells=tf.querySelectorAll('td');
                const g=cells[2],y=cells[5];
                if(g&&y){
                    const gv=parseFloat(g.textContent.replace('%','').trim())||0;
                    const yv=parseFloat(y.textContent.replace('%','').trim())||0;
                    if(gv>yv)g.classList.add('total-green-over-yellow');else g.classList.remove('total-green-over-yellow');
                }
            }
        }

        function refreshTables(picked){
            const {stats,days}=buildStats(picked);
            updateTableByStats('tblAdder',stats,days,true,picked);
            updateTableByStats('tblNonAdder',stats,days,false,picked);
            renderInlineChartDetails(picked);
            renderDownAdderSummary(stats,picked);
            renderSchedule(picked);
        }

        // ===== 測機排程表（連續週期引擎）=====
        // 每台 chamber 只在自己班別(日測/夜測)出現。
        // ev: 週期事件 {items:'A+B', every:N天, from:'YYYY-MM-DD' 基準日}；
        //     某天若 (該天-基準日) 為 every 的整數倍即命中，連續跨週推算。
        // cells: 尚未提供週期規則者，暫用固定週樣板(鍵=週內第幾天,0=週二)。
        const ITEM_ORDER=['HTSIN130_11','PEOX50A','5.5K','USG50','CHC 2K','DAILY2_PA','DAILY4_PA','D2_PA','D4_PA','DAILY_PA','XFER','Weekly PA'];
        function itemRank(t){const i=ITEM_ORDER.indexOf(t);return i<0?ITEM_ORDER.length-0.5:i;}
        const SCHEDULE=[
            { title:'NISACVD', rows:[
                { name:'NISACVD-B01', shift:'日', cells:{3:'XFER',4:'HTSIN130_11\nPEOX50A',5:'XFER'} },
                { name:'NISACVD-B06', shift:'日', cells:{3:'HTSIN130_11\nPEOX50A\nXFER',4:'HTSIN130_11\nPEOX50A\nXFER\nWeekly PA',6:'HTSIN130_11\nPEOX50A\nXFER'} },
                { name:'NISACVD-B07', shift:'日', cells:{0:'HTSIN130_11\nPEOX50A\nXFER',2:'Weekly PA',3:'HTSIN130_11\nPEOX50A\nXFER'} },
                { name:'NISACVD-B08', shift:'夜', cells:{1:'HTSIN130_11\nPEOX50A\nXFER',4:'HTSIN130_11\nPEOX50A\nXFER',5:'Weekly PA'} },
                { name:'NISACVD-B03', shift:'夜', cells:{0:'XFER',1:'DAILY_PA',3:'XFER',4:'DAILY_PA',6:'XFER'} },
                { name:'NISACVD-B12', shift:'日', cells:{1:'DAILY_PA\nXFER',4:'DAILY_PA\nXFER'} },
                { name:'NISACVD-B13', shift:'夜', cells:{0:'DAILY_PA\nXFER',3:'DAILY_PA\nXFER\nXFER',6:'DAILY_PA\nXFER'} },
                { name:'NISACVD-B14', shift:'日', cells:{0:'DAILY_PA\nXFER',3:'DAILY_PA\nXFER\nXFER',6:'DAILY_PA\nXFER'} }
            ]},
            { title:'SACVD (5.5K)', rows:[
                { name:'SACVD-B01', shift:'日', cells:{1:'5.5K\nXFER',4:'5.5K\nXFER'} },
                { name:'SACVD-B04', shift:'夜', cells:{2:'5.5K\nXFER',5:'5.5K\nXFER'} },
                { name:'SACVD-B06', shift:'夜', cells:{0:'5.5K\nXFER',3:'5.5K\nXFER',6:'5.5K\nXFER'} },
                { name:'SACVD-B08', shift:'日', cells:{2:'5.5K\nXFER',5:'5.5K\nXFER'} },
                { name:'SACVD-B09', shift:'日', cells:{0:'5.5K\nXFER',3:'5.5K\nXFER',6:'5.5K\nXFER'} },
                { name:'SACVD-B10', shift:'日', cells:{0:'5.5K\nXFER',3:'5.5K\nXFER',6:'5.5K\nXFER'} }
            ]},
            { title:'SACVD (USG50)', rows:[
                { name:'SACVD-B02', shift:'夜', cells:{1:'USG50',2:'CHC 2K\nXFER',3:'USG50',5:'USG50\nCHC 2K\nXFER',6:'USG50'} },
                { name:'SACVD-B11', shift:'日', cells:{0:'USG50',1:'XFER',2:'USG50',4:'USG50\nXFER',6:'USG50'} },
                { name:'SACVD-B12', shift:'夜', cells:{0:'USG50\nXFER',2:'USG50',3:'XFER',4:'USG50',6:'USG50\nXFER'} }
            ]},
            { title:'SACVD-B03B / B03C / B07A 只測 SABOX110 PA', rows:[
                { name:'SACVD-B03', shift:'日', cells:{0:'DAILY2_PA\nDAILY4_PA',2:'DAILY2_PA\nXFER',4:'DAILY2_PA\nDAILY4_PA',5:'XFER',6:'DAILY2_PA'} },
                { name:'SACVD-B05', shift:'夜', cells:{0:'XFER',1:'D2_PA',3:'D2_PA\nD4_PA\nXFER',5:'D2_PA',6:'XFER'} },
                { name:'SACVD-B07', shift:'夜', cells:{0:'D2_PA',1:'XFER',2:'D2_PA\nD4_PA',4:'D2_PA\nXFER',6:'D2_PA\nD4_PA'} }
            ]}
        ];
        function schedCell(row,date,idx){
            if(row.ev){
                const items=[];
                row.ev.forEach(ev=>{
                    const a=new Date(ev.from+'T00:00:00');
                    const diff=Math.round((date-a)/86400000);
                    if(((diff%ev.every)+ev.every)%ev.every===0)
                        ev.items.split('+').forEach(t=>{t=t.trim();if(t&&items.indexOf(t)<0)items.push(t);});
                });
                items.sort((a,b)=>itemRank(a)-itemRank(b));
                return items.join('\n');
            }
            return (row.cells&&row.cells[idx])||'';
        }
        function renderSchedule(picked){
            const box=document.getElementById('downSchedule');
            if(!box)return;
            const start=startTuesdayFor(picked);
            const dates=[];for(let i=0;i<7;i++){dates.push(new Date(start.getFullYear(),start.getMonth(),start.getDate()+i));}
            const md=d=>(d.getMonth()+1)+'月'+d.getDate()+'日';
            const esc=v=>String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;');
            const cell=t=>esc(t).replace(/\n/g,'<br>');
            let html='';
            SCHEDULE.forEach(g=>{
                html+='<div class="sched-title">'+esc(g.title)+'</div>';
                html+='<div class="sched-scroll"><table class="sched"><thead><tr><th rowspan="2" class="sched-ent">Entity</th>';
                dates.forEach(d=>{html+='<th colspan="2">'+md(d)+'</th>';});
                html+='</tr><tr>';
                dates.forEach(()=>{html+='<th>日測</th><th>夜測</th>';});
                html+='</tr></thead><tbody>';
                g.rows.forEach(r=>{
                    html+='<tr><td class="sched-ent">'+esc(r.name)+'('+esc(r.shift)+')</td>';
                    for(let i=0;i<7;i++){
                        const t=schedCell(r,dates[i],i);
                        html+='<td>'+(r.shift==='日'?cell(t):'')+'</td><td>'+(r.shift==='夜'?cell(t):'')+'</td>';
                    }
                    html+='</tr>';
                });
                html+='</tbody></table></div>';
            });
            box.innerHTML=html;
        }

        // down chart 作業區上方：各 entity 的 ADDER Target vs 本週 alarm 數
        function fmtMD(d){return String(d.getMonth()+1).padStart(2,'0')+'/'+String(d.getDate()).padStart(2,'0');}
        function renderDownAdderSummary(stats,picked){
            const box=document.getElementById('downAdderSummary');
            if(!box)return;
            const start=startTuesdayFor(picked);
            const end=new Date(start.getFullYear(),start.getMonth(),start.getDate()+6);
            const wk='W'+getWeekNumber(start)+'('+fmtMD(start)+'~'+fmtMD(end)+')';
            let html='';
            ['NISACVD','SACVD'].forEach(ent=>{
                const target=getWeeklyTargetCount(ent,true);
                const cnt=(stats[ent]&&stats[ent].sum.alarmAdder)||0;
                html+=`<table class="down-sum"><tbody>
                    <tr><th class="ds-title" colspan="3">${ent} Alarm Counts</th></tr>
                    <tr><td class="ds-corner"></td><td class="ds-h">Target</td><td class="ds-h">${wk}</td></tr>
                    <tr><td class="ds-rowh">ADDER</td><td class="ds-v">${target}</td><td class="ds-v">${cnt}</td></tr>
                </tbody></table>`;
            });
            box.innerHTML=html;
        }

        // ===== Chart Alarm Detail =====
        function escapeHtml(s){return String(s==null?'':s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#39;');}
        function getChartAlarmDetail(start,entity,isAdder){return chartAlarmStats[fmtYMDDash(start)+'|'+entity+'|'+(isAdder?'ADDER':'NON_ADDER')]||null;}
        function getChartAlarmDateDetail(start,entity,isAdder){return chartAlarmDateStats[fmtYMDDash(start)+'|'+entity+'|'+(isAdder?'ADDER':'NON_ADDER')]||null;}
        function buildChartUrl(chartId){if(!chartId)return null;return 'http://10.10.101.170/projectsite/SPCTool/PreviewMultiSPCTypeChart.aspx?site=12AP58&ChartList=NPW:'+encodeURIComponent(chartId);}

        function buildInlineChartDetailHtml(picked,isAdder){
            const start=startTuesdayFor(picked);
            const blockLabel=isAdder?'ADDER':'NON-ADDER';
            const entities=['NISACVD','SACVD'];
            const chartNameFreq={};
            const allRows=[];

            for(const entity of entities){
                const chartMap=getChartAlarmDetail(start,entity,isAdder)||{};
                const dateMap=getChartAlarmDateDetail(start,entity,isAdder)||{};
                for(const ck in chartMap){
                    const cnt=chartMap[ck];
                    const [chartId,chartName]=ck.split('||');
                    const nameKey=(chartName||'').toString().trim().toUpperCase();
                    if(nameKey)chartNameFreq[nameKey]=(chartNameFreq[nameKey]||0)+1;
                    const dateSet=dateMap[ck];
                    const dates=dateSet?Array.from(dateSet).sort():[];
                    const mkey=fmtYMDDash(start)+'|'+entity+'|'+(isAdder?'ADDER':'NON_ADDER')+'|'+ck;
                    const measurePu=chartMeasurePu[mkey]||'';
                    const processUnit=chartProcUnit[mkey]||'';
                    const seqSet=chartAlarmSeq[mkey];
                    const chartSeq=(seqSet&&seqSet.size)?Array.from(seqSet)[0]:'';
                    const pointValue=chartAlarmMean[mkey];
                    const wafer=chartAlarmWafer[mkey];
                    const parameter=chartParameter[mkey];
                    allRows.push({entity,chartId,chartName,cnt,nameKey,dates,measurePu,processUnit,chartSeq,pointValue,wafer,parameter});
                }
            }

            if(allRows.length===0)return `<div class="inline-empty">${blockLabel}：本週 NISACVD / SACVD 無 Alarm 記錄。</div>`;

            function entityOrder(e){if(e==='NISACVD')return 0;if(e==='SACVD')return 1;return 99;}
            allRows.sort((a,b)=>{
                if(!isAdder){
                    const ak=/RANGE|U%/i.test(String(a.chartName||''))?0:1;
                    const bk=/RANGE|U%/i.test(String(b.chartName||''))?0:1;
                    if(ak!==bk)return ak-bk;
                }
                const ea=entityOrder(a.entity),eb=entityOrder(b.entity);
                if(ea!==eb)return ea-eb;
                if(b.cnt!==a.cnt)return b.cnt-a.cnt;
                return String(a.chartName||'').localeCompare(String(b.chartName||''));
            });

            const colCount=isAdder?9:8;
            let head=`<tr><th colspan="${colCount}">${blockLabel} - Chart Alarm Detail (W${getWeekNumber(start)})</th></tr>
                <tr><th style="width:80px;">Entity</th><th style="width:80px;">CHART_ID</th><th class="cn-col">CHART_NAME</th>
                <th style="width:70px;text-align:center;">Alarm 次數</th><th style="width:160px;">ALARM 日期</th>`;
            if(isAdder)head+=`<th style="width:380px;text-align:center;">Trend_Chart</th><th style="width:200px;text-align:center;">PRE_Map</th><th style="width:200px;text-align:center;">ADDER_Map</th><th style="width:110px;">Measure_Tool</th>`;
            else head+=`<th style="width:380px;text-align:center;">Trend_Chart</th><th style="width:200px;text-align:center;">Profile</th><th style="width:110px;">Measure_Tool</th>`;
            head+=`</tr>`;

            let html=`<table class="chart-detail"><thead>${head}</thead><tbody>`;
            for(const r of allRows){
                const url=buildChartUrl(r.chartId);
                const nameHtml=url?`<a href="${url}" target="_blank" rel="noopener noreferrer">${escapeHtml(r.chartName||'')}</a>`:escapeHtml(r.chartName||'');
                const dupByName=r.nameKey&&(chartNameFreq[r.nameKey]>=2);
                const dupByMultiDay=Array.isArray(r.dates)&&r.dates.length>=2;
                const isDup=dupByName||dupByMultiDay;
                const datesText=(r.dates&&r.dates.length)?r.dates.join(', '):'';
                const nonAdderDim=(!isAdder)&&!/RANGE|U%/i.test(String(r.chartName||''));
                const rowClass=isDup?'dup-chart':(nonAdderDim?'dim-row':'');
                const cid=escapeHtml(r.chartId||''),cname=escapeHtml(r.chartName||'');
                const puUp=String(r.processUnit||'').trim().toUpperCase();
                const site=puUp.startsWith('OXSE-A')?'12AP14':'12AP58';
                const seq=escapeHtml(r.chartSeq||'');
                const pv=escapeHtml(r.pointValue==null?'':String(r.pointValue));
                const da=`data-site="${site}" data-uchart-id="${cid}" data-chart-seq="${seq}" data-point-value="${pv}"`;
                const puInit=escapeHtml(parseMeasurePu(r.measurePu));
                const previewCell=`<td class="npw-cell-preview"><div class="npw-spark" data-cid="${cid}" data-block="${isAdder?'A':'N'}"><canvas></canvas></div></td>`;
                const measureCell=`<td><span class="map-info" ${da}>${puInit||'<span style="color:#999;">...</span>'}</span></td>`;
                let extra='';
                if(isAdder){
                    extra=previewCell+
                          `<td class="npw-cell-map"><span class="pre-map" ${da} style="color:#999;">...</span></td>`+
                          `<td class="npw-cell-map"><span class="adder-map" ${da} style="color:#999;">...</span></td>`+
                          measureCell;
                }else{
                    const waferAttr=`data-wafer="${escapeHtml(r.wafer==null?'':String(r.wafer))}"`;
                    const profileCell=`<td class="npw-cell-map"><span class="profile-img" data-site="${site}" data-cid="${cid}" data-seq="${seq}" data-pv="${pv}" ${waferAttr} style="color:#999;">...</span></td>`;
                    extra=previewCell+profileCell+measureCell;
                }
                html+=`<tr class="${rowClass}"><td>${escapeHtml(r.entity)}</td><td>${cid}</td><td class="cn-col">${nameHtml}</td>
                    <td style="text-align:center;">${escapeHtml(r.cnt)}</td><td>${escapeHtml(datesText)}</td>${extra}</tr>`;
            }
            html+='</tbody></table>';
            return html;
        }

        // ===== Preview 趨勢圖（Chart.js）+ PRE/ADDER MAP / MeasurePU（沿用 refer.html proxy）=====
        let sparkInstances=[];
        // Map / MeasurePU 代理（與 refer.html 相同）。路徑相對於本頁，視部署位置調整。
        const MAP_PROXY = 'TF2api/SpcMapInfoProxy.ashx';

        // NON-ADDER profile 單張 RAW 圖：由後端 op=profileimg 抓 contour 頁、擷取單張圖網址。

        // MEASUREPU 顯示用：取 ^SP5^ 後面那段（如 KLA-Tencor^SP5^CUSFSCAN-B05 -> CUSFSCAN-B05）
        function parseMeasurePu(s){
            if(s==null)return '';
            const str=String(s);
            const m=str.match(/\^SP5\^([^\^\s<]+)/i);
            return m?m[1]:str;
        }

        // 趨勢圖 Y 軸範圍：上界 = 該 chart UCL×(1+pct)，下界 = LCL×(1-pct)
        const YBOUND_PCT = 0.10;  // UCL/LCL 各 ±10%

        // 代表 XBAR（取最後一個有效的 CL 值）
        function reprVal(pts,key){for(let i=pts.length-1;i>=0;i--){const v=pts[i]&&pts[i][key];if(v!=null&&isFinite(Number(v)))return Number(v);}return null;}

        // Chart.js 趨勢圖（Tool-ABC 樣式：MEAN_VALUE/UCL/XBAR(CL)/+1σ/+2σ + 圖例 + 軸）
        // opts: {yMin,yMax} 固定範圍；或 {uclLclPct} 以 UCL×(1+pct)/LCL×(1-pct) 卡上下界。
        function drawSpark(canvas,pts,days,cid,opts){
            if(!canvas||!window.Chart||!pts||!pts.length)return;
            opts=opts||{};
            let yMin=(opts.yMin!=null)?opts.yMin:null, yMax=(opts.yMax!=null)?opts.yMax:null;
            if(opts.uclLclPct!=null){
                const u=reprVal(pts,'ucl'), l=reprVal(pts,'lcl');
                if(u!=null)yMax=u*(1+opts.uclLclPct);
                yMin=(l!=null)?l*(1-opts.uclLclPct):0;
            }
            const hasMin=(yMin!=null),hasMax=(yMax!=null);
            const labels=pts.map(p=>String(p.d||'').replace('T',' '));
            const meanRaw=pts.map(p=>p.mean==null?null:Number(p.mean));
            const ucl=pts.map(p=>p.ucl==null?null:Number(p.ucl));
            const lcl=pts.map(p=>p.lcl==null?null:Number(p.lcl));
            const cl=pts.map(p=>p.xbar==null?null:Number(p.xbar));
            const set=new Set(days);
            const alarmPt=pts.map(p=>Number(p.alarm)>=1 && set.has(String(p.d||'').substring(0,10)));
            // 超出上下界的點裁到邊界並標紅（tooltip 仍顯示真值）
            const overTop=meanRaw.map(v=>hasMax&&Number.isFinite(v)&&v>yMax);
            const underBot=meanRaw.map(v=>hasMin&&Number.isFinite(v)&&v<yMin);
            const mean=meanRaw.map((v,i)=>v==null?null:(overTop[i]?yMax:(underBot[i]?yMin:v)));
            const ptColor=alarmPt.map((a,i)=>(a||overTop[i]||underBot[i])?'red':'#000');
            const ptRadius=alarmPt.map((a,i)=>(a||overTop[i]||underBot[i])?5:3);
            const yScale={ticks:{font:{size:9}}};
            if(hasMin)yScale.min=yMin;
            if(hasMax)yScale.max=yMax;
            if(!hasMin&&!hasMax)yScale.beginAtZero=true;

            const meanDs={label:'MEAN_VALUE',data:mean,borderColor:'#000',backgroundColor:'rgba(0,0,0,0.1)',pointStyle:'triangle',fill:false,tension:.2,borderWidth:1.5,pointBackgroundColor:ptColor,pointBorderColor:ptColor,pointRadius:ptRadius,pointHoverRadius:6};
            let datasets;
            if(opts.block==='N'){
                // NON-ADDER：7 條管制線（用 DB 帶值 AVG1STD/AVG_1STD/AVG2STD/AVG_2STD/UCL/LCL/XBAR）
                const avg1=pts.map(p=>p.avg1==null?null:Number(p.avg1));   // +1σ
                const avgn1=pts.map(p=>p.avgn1==null?null:Number(p.avgn1));// -1σ
                const avg2=pts.map(p=>p.avg2==null?null:Number(p.avg2));   // +2σ
                const avgn2=pts.map(p=>p.avgn2==null?null:Number(p.avgn2));// -2σ
                const line=(label,data,color,dash)=>({label,data,borderColor:color,borderDash:dash,fill:false,pointRadius:0,borderWidth:1.2,spanGaps:true});
                datasets=[meanDs,
                    line('UCL',ucl,'red',[4,2]),
                    line('+2σ',avg2,'orange',[6,2]),
                    line('+1σ',avg1,'#1976d2',[2,2]),
                    line('XBAR (CL)',cl,'#0f766e',[0,0]),
                    line('-1σ',avgn1,'#1976d2',[2,2]),
                    line('-2σ',avgn2,'orange',[6,2]),
                    line('LCL',lcl,'red',[4,2])
                ];
            }else{
                // ADDER：MEAN_VALUE/UCL/XBAR(CL)/+1σ/+2σ（單側）
                const p1=pts.map(p=>(p.xbar==null||p.sigma==null)?null:Number(p.xbar)+Number(p.sigma));
                const p2=pts.map(p=>(p.xbar==null||p.sigma==null)?null:Number(p.xbar)+2*Number(p.sigma));
                datasets=[meanDs,
                    {label:'UCL',data:ucl,borderColor:'red',borderDash:[4,2],fill:false,pointRadius:0,borderWidth:1.5,spanGaps:true},
                    {label:'XBAR (CL)',data:cl,borderColor:'#0f766e',fill:false,pointRadius:0,borderWidth:1.5,spanGaps:true},
                    {label:'+1σ (XBAR+σ)',data:p1,borderColor:'#1976d2',borderDash:[2,2],fill:false,pointRadius:0,borderWidth:1,spanGaps:true},
                    {label:'+2σ (XBAR+2σ)',data:p2,borderColor:'orange',borderDash:[6,2],fill:false,pointRadius:0,borderWidth:1,spanGaps:true}
                ];
            }
            const inst=new Chart(canvas.getContext('2d'),{
                type:'line',
                data:{labels,datasets},
                options:{animation:false,responsive:true,maintainAspectRatio:false,
                    layout:{padding:{top:4}},
                    plugins:{
                        legend:{display:true,position:'top',align:'end',labels:{usePointStyle:true,pointStyle:'line',boxWidth:26,boxHeight:8,padding:8,font:{size:9,weight:'700'}}},
                        tooltip:{callbacks:{label:c=>{
                            if(c.dataset.label==='MEAN_VALUE'){const rv=meanRaw[c.dataIndex];return 'MEAN_VALUE: '+(rv==null?'-':rv)+(overTop[c.dataIndex]?' (>上限)':(underBot[c.dataIndex]?' (<下限)':''));}
                            return c.dataset.label+': '+c.formattedValue;
                        }}}
                    },
                    scales:{
                        x:{ticks:{font:{size:8},maxRotation:90,minRotation:90,autoSkip:true,maxTicksLimit:14}},
                        y:yScale
                    }
                }
            });
            sparkInstances.push(inst);
        }

        // 畫 Preview/Chart 縮圖（Chart.js，資料來自 op=chartdata；ADDER 與 NON-ADDER 皆畫）
        async function hydratePreviews(picked){
            sparkInstances.forEach(c=>{try{c.destroy();}catch(e){}});sparkInstances=[];
            const sparks=[...document.querySelectorAll('#adderChartDetail .npw-spark[data-cid], #nonAdderChartDetail .npw-spark[data-cid]')];
            const cids=[...new Set(sparks.map(e=>e.getAttribute('data-cid')).filter(Boolean))];
            if(!cids.length)return;
            const start=startTuesdayFor(picked);
            const days=[];for(let i=0;i<7;i++){const d=new Date(start.getFullYear(),start.getMonth(),start.getDate());d.setDate(start.getDate()+i);days.push(fmtYMDDash(d));}
            const weekEnd=new Date(start.getFullYear(),start.getMonth(),start.getDate());weekEnd.setDate(start.getDate()+6);
            let series={};
            try{
                const qs=new URLSearchParams({op:'chartdata',cids:cids.join(','),end:fmtYMDDash(weekEnd),days:'60'});
                const res=await fetch(PAGE+'?'+qs.toString(),{cache:'no-store'});
                const data=await res.json();
                if(data.ok)series=data.series||{};
            }catch(e){console.error(e);}
            sparks.forEach(el=>{
                const cid=el.getAttribute('data-cid');
                const block=el.getAttribute('data-block');
                const opts={block:block==='A'?'A':'N',uclLclPct:YBOUND_PCT};
                drawSpark(el.querySelector('canvas'),series[cid]||[],days,cid,opts);
            });
        }

        // 共用：以併發方式對一組節點查 MAP 代理，再交給 apply 回填
        // extraQuery：額外附加在 URL 後（如 profile 的 &keyword=RAW）
        function mapThumbHtml(imgUrl,alt){
            return `<a href="openie:${encodeURIComponent(imgUrl)}" target="_blank" rel="noopener noreferrer" title="Open ${alt} (IE)">`
                + `<img class="adder-map-thumb" src="${escapeHtml(imgUrl)}" alt="${alt}" loading="lazy" /></a>`;
        }

        // ===== Map/Profile：捲到才載入 + 去重 + 快取 + 限流 =====
        const MAP_CONC = 3;                 // 對目標伺服器的最大同時請求數
        let _mapActive = 0; const _mapQueue = [];
        function _mapSchedule(fn){ return new Promise(res=>{ _mapQueue.push({fn,res}); _mapPump(); }); }
        function _mapPump(){
            while(_mapActive<MAP_CONC && _mapQueue.length){
                const job=_mapQueue.shift(); _mapActive++;
                Promise.resolve().then(job.fn).then(r=>{_mapActive--;job.res(r);_mapPump();},()=>{_mapActive--;job.res(null);_mapPump();});
            }
        }
        const _enc=encodeURIComponent;
        const _proxyCache={};   // SpcMapInfoProxy 結果（PRE/ADDER/MeasurePU 共用）
        const _profileCache={}; // op=profileimg 結果
        function fetchProxy(site,uchartId,chartSeq,pv){
            const key=site+'|'+uchartId+'|'+chartSeq+'|'+pv;
            if(_proxyCache[key])return _proxyCache[key];
            const url=MAP_PROXY+`?site=${_enc(site)}&uchart_id=${_enc(uchartId)}&chart_seq=${_enc(chartSeq)}&PointValue=${_enc(pv!==''?pv:'10')}`;
            _proxyCache[key]=_mapSchedule(()=>fetch(url,{credentials:'include'}).then(r=>r.ok?r.json():null).catch(()=>null));
            return _proxyCache[key];
        }
        function fetchProfile(site,cid,seq,pv,wafer){
            const key=site+'|'+cid+'|'+seq+'|'+pv+'|'+wafer;
            if(_profileCache[key])return _profileCache[key];
            const u=PAGE+'?op=profileimg&chartId='+_enc(cid)+'&chartSeq='+_enc(seq)+'&pointValue='+_enc(pv)+'&site='+_enc(site)+'&wafer='+_enc(wafer);
            _profileCache[key]=_mapSchedule(()=>fetch(u,{cache:'no-store'}).then(r=>r.ok?r.json():null).catch(()=>null));
            return _profileCache[key];
        }

        function applyProxy(el,d){
            if(el.classList.contains('map-info')){
                if(!d){el.textContent=(el.textContent&&el.textContent!=='...')?el.textContent:'-';return;}
                el.style.color='#111';
                el.textContent=d.measurePU?parseMeasurePu(d.measurePU):((el.textContent&&el.textContent!=='...')?el.textContent:'-');
            }else if(el.classList.contains('pre-map')){
                el.innerHTML=(d&&d.preMapImgUrl)?mapThumbHtml(String(d.preMapImgUrl),'PRE MAP'):'-';
            }else if(el.classList.contains('adder-map')){
                el.innerHTML=(d&&d.adderMapImgUrl)?mapThumbHtml(String(d.adderMapImgUrl),'ADDER MAP'):'-';
            }
        }
        async function hydrateOne(el){
            if(el.dataset.hydrated)return; el.dataset.hydrated='1';
            const site=el.getAttribute('data-site')||'12AP58';
            if(el.classList.contains('profile-img')){
                const cid=el.getAttribute('data-cid')||'',seq=el.getAttribute('data-seq')||'',pv=el.getAttribute('data-pv')||'',wafer=el.getAttribute('data-wafer')||'';
                if(!cid||!seq){el.textContent='-';return;}
                const d=await fetchProfile(site,cid,seq,pv,wafer);
                if(d&&d.ok&&d.imgUrl)el.innerHTML=mapThumbHtml(String(d.imgUrl),'Profile RAW'); else el.textContent='-';
            }else{
                const uchartId=el.getAttribute('data-uchart-id')||'',chartSeq=el.getAttribute('data-chart-seq')||'',pv=el.getAttribute('data-point-value')||'';
                if(!chartSeq){el.textContent='-';return;}
                const d=await fetchProxy(site,uchartId,chartSeq,pv);
                applyProxy(el,(d&&d.ok)?d:null);
            }
        }
        let _mapObserver=null;
        function setupLazyMaps(){
            const els=[...document.querySelectorAll('#adderChartDetail .map-info, #adderChartDetail .pre-map, #adderChartDetail .adder-map, #nonAdderChartDetail .map-info, #nonAdderChartDetail .profile-img')];
            if(_mapObserver)_mapObserver.disconnect();
            if(!('IntersectionObserver' in window)){ els.forEach(hydrateOne); return; } // 後備：一次載入
            _mapObserver=new IntersectionObserver((entries)=>{
                entries.forEach(en=>{ if(en.isIntersecting){ _mapObserver.unobserve(en.target); hydrateOne(en.target); } });
            },{rootMargin:'250px'});
            els.forEach(el=>_mapObserver.observe(el));
        }

        function renderInlineChartDetails(picked){
            const a=document.getElementById('adderChartDetail');
            const n=document.getElementById('nonAdderChartDetail');
            if(a)a.innerHTML=buildInlineChartDetailHtml(picked,true);
            if(n)n.innerHTML=buildInlineChartDetailHtml(picked,false);
            hydratePreviews(picked);  // Chart.js 趨勢縮圖（chartdata 單次批次查詢）
            setupLazyMaps();          // PRE/ADDER/Profile/MeasurePU：捲到才載入+去重+快取+限流
        }

        // ===== 初始化 =====
        (function init(){
            const input=document.getElementById('pickDate');
            const weekHint=document.getElementById('weekHint');
            function updateWeekHint(d){weekHint.textContent='W'+getWeekNumber(startTuesdayFor(d));}

            const today=new Date();
            input.value=toISODateLocal(today);
            setHeadersByPickedDate(today);
            updateWeekHint(today);

            const dcDate=document.getElementById('dcDate');
            const dcWeek=document.getElementById('dcWeek');
            // 報表日期選擇器與作業區週別選擇器同步同一週
            function syncWeekControls(picked){
                const iso=toISODateLocal(picked);
                if(input.value!==iso)input.value=iso;
                if(dcDate&&dcDate.value!==iso)dcDate.value=iso;
                if(dcWeek){const s=startTuesdayFor(picked);const e=new Date(s.getFullYear(),s.getMonth(),s.getDate()+6);dcWeek.textContent='W'+getWeekNumber(s)+'（'+fmtMD(s)+'~'+fmtMD(e)+'）';}
            }

            async function reload(picked){
                setHeadersByPickedDate(picked);
                updateWeekHint(picked);
                syncWeekControls(picked);
                try{await loadFromDb(picked);refreshTables(picked);}catch(e){/* 已顯示 */}
            }

            const calBtn=document.getElementById('calBtn');
            if(calBtn)calBtn.addEventListener('click',()=>{
                if(typeof input.showPicker==='function'){try{input.showPicker();return;}catch(e){}}
                input.focus();
            });

            document.getElementById('reloadBtn').addEventListener('click',()=>{
                const picked=input.value?new Date(input.value+'T00:00:00'):new Date();
                reload(picked);
            });
            input.addEventListener('change',()=>{
                if(!input.value)return;
                reload(new Date(input.value+'T00:00:00'));
            });

            // 作業區週別選擇
            const curWeek=()=>{const v=(dcDate&&dcDate.value)||input.value;return v?new Date(v+'T00:00:00'):new Date();};
            if(dcDate)dcDate.addEventListener('change',()=>{if(dcDate.value)reload(new Date(dcDate.value+'T00:00:00'));});
            const dcPrev=document.getElementById('dcPrev'),dcNext=document.getElementById('dcNext');
            if(dcPrev)dcPrev.addEventListener('click',()=>{const d=curWeek();d.setDate(d.getDate()-7);reload(d);});
            if(dcNext)dcNext.addEventListener('click',()=>{const d=curWeek();d.setDate(d.getDate()+7);reload(d);});

            reload(today);
        })();
    })();
    </script>

    <!-- ============================================================
         AI chat widget
         ============================================================ -->
    <button id="aiBubble" type="button" title="AI 助理">AI</button>
    <div id="aiPanel" hidden>
        <div class="ai-sidebar">
            <button type="button" id="aiNewChat" class="ai-new-btn">+ 新聊天</button>
            <div id="aiSessionList" class="ai-sess-list"></div>
        </div>
        <div class="ai-main">
            <div class="ai-head">
                <input type="text" id="aiTitle" class="ai-title-input" placeholder="對話標題" />
                <button type="button" id="aiClose" title="關閉">×</button>
            </div>
            <div id="aiMessages" class="ai-msgs"></div>
            <div id="aiPreview" class="ai-preview" hidden>
                <img id="aiPreviewImg" alt="附加圖片" />
                <span class="ai-prev-meta" id="aiPreviewMeta"></span>
                <button type="button" class="ai-prev-remove" id="aiPreviewRemove">移除</button>
            </div>
            <div class="ai-input-wrap">
                <button type="button" id="aiAttach" class="ai-icon-btn" title="附加圖片">
                    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/>
                    </svg>
                </button>
                <input type="file" id="aiFile" accept="image/*" hidden />
                <textarea id="aiInput" placeholder="輸入問題,Enter 送出,Shift+Enter 換行" rows="2"></textarea>
                <button type="button" id="aiSend">送出</button>
            </div>
        </div>
    </div>

    <script>
        // ============================================================
        //  AI Chat Widget -- talks to NPW_Alarm.aspx?op=chat (no auth).
        // ============================================================
        (function () {
            const PROXY_URL = (location.pathname.split('/').pop() || 'NPW_Alarm.aspx') + '?op=chat';
            const STORAGE_KEY = 'webTemplateLite.aiSessions';
            const ACTIVE_KEY  = 'webTemplateLite.aiActiveId';

            const $ = id => document.getElementById(id);
            const bubble = $('aiBubble'), panel = $('aiPanel'), closeBtn = $('aiClose');
            const msgs = $('aiMessages'), input = $('aiInput'), sendBtn = $('aiSend');
            const attachBtn = $('aiAttach'), fileInput = $('aiFile');
            const previewBox = $('aiPreview'), previewImg = $('aiPreviewImg');
            const previewMeta = $('aiPreviewMeta'), previewRemove = $('aiPreviewRemove');
            const newChatBtn = $('aiNewChat'), sessionListEl = $('aiSessionList');
            const titleInput = $('aiTitle');

            let sessions = [], activeId = null, busy = false, attachedImage = null;

            // ---- Overlay for image zoom ----
            let overlay = null;
            function openOverlay(src) {
                closeOverlay();
                overlay = document.createElement('div');
                overlay.className = 'img-overlay';
                const img = document.createElement('img');
                const sizeIt = () => {
                    const nw = img.naturalWidth, nh = img.naturalHeight;
                    if (!nw || !nh) return;
                    const s = Math.min(2, innerWidth*0.95/nw, innerHeight*0.95/nh);
                    img.style.width  = (nw*s) + 'px';
                    img.style.height = (nh*s) + 'px';
                };
                img.onload = sizeIt; img.src = src; if (img.complete) sizeIt();
                overlay.appendChild(img);
                overlay.addEventListener('click', closeOverlay);
                document.body.appendChild(overlay);
            }
            function closeOverlay() { if (overlay && overlay.parentNode) overlay.parentNode.removeChild(overlay); overlay = null; }
            document.addEventListener('keydown', e => { if (e.key === 'Escape') closeOverlay(); });

            // ---- Sessions ----
            function uid() { return 'sess-' + Date.now() + '-' + Math.random().toString(36).slice(2, 6); }
            function loadSessions() {
                try { sessions = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]'); activeId = localStorage.getItem(ACTIVE_KEY) || null; }
                catch (e) { sessions = []; activeId = null; }
                if (!Array.isArray(sessions)) sessions = [];
                if (sessions.length === 0) createSession(false);
                else if (!sessions.find(s => s.id === activeId)) activeId = sessions[0].id;
            }
            function saveSessions() {
                try { localStorage.setItem(STORAGE_KEY, JSON.stringify(sessions)); if (activeId) localStorage.setItem(ACTIVE_KEY, activeId); }
                catch (e) {}
            }
            function getActive() { return sessions.find(s => s.id === activeId); }
            function createSession(rerender) {
                const s = { id: uid(), title: '新對話', tags: [], history: [], createdAt: Date.now() };
                sessions.unshift(s); activeId = s.id;
                saveSessions();
                if (rerender !== false) { renderSessionList(); renderActiveSession(); clearAttachment(); input.focus(); }
            }
            function switchSession(id) { if (busy) return; activeId = id; saveSessions(); renderSessionList(); renderActiveSession(); clearAttachment(); }
            function deleteSession(id) {
                if (busy) return;
                const s = sessions.find(x => x.id === id);
                if (!s) return;
                if (!confirm('刪除「' + (s.title || '新對話') + '」?')) return;
                sessions = sessions.filter(x => x.id !== id);
                if (activeId === id) activeId = sessions.length > 0 ? sessions[0].id : null;
                if (sessions.length === 0) createSession(false);
                saveSessions(); renderSessionList(); renderActiveSession();
            }
            function maybeAutoTitle(s, text) {
                if (s.title === '新對話' && text) {
                    const t = text.replace(/\s+/g, ' ').trim();
                    s.title = t.length > 26 ? t.slice(0, 26) + '...' : t;
                    titleInput.value = s.title;
                }
            }

            // ---- Render ----
            function renderSessionList() {
                sessionListEl.innerHTML = '';
                sessions.forEach(s => {
                    const item = document.createElement('div');
                    item.className = 'ai-sess' + (s.id === activeId ? ' active' : '');
                    const t = document.createElement('div'); t.className = 'ai-sess-title'; t.textContent = s.title || '新對話';
                    item.appendChild(t);
                    const del = document.createElement('button'); del.type = 'button'; del.className = 'ai-sess-del'; del.textContent = '×';
                    del.addEventListener('click', e => { e.stopPropagation(); deleteSession(s.id); });
                    item.appendChild(del);
                    item.addEventListener('click', () => switchSession(s.id));
                    sessionListEl.appendChild(item);
                });
            }
            function renderActiveSession() {
                const s = getActive();
                msgs.innerHTML = '';
                if (!s) return;
                titleInput.value = s.title || '';
                if (s.history.length === 0) appendMessage('assistant', '你好,有什麼可以幫你的?');
                else s.history.forEach(m => {
                    if (m.role === 'user') {
                        if (Array.isArray(m.content)) {
                            const t = (m.content.find(p => p.type === 'text') || {}).text || '';
                            const u = (m.content.find(p => p.type === 'image_url') || {}).image_url;
                            appendUserMessage(t, u ? u.url : null);
                        } else appendUserMessage(m.content, null);
                    } else if (m.role === 'assistant') appendMessage('assistant', m.content);
                });
            }
            function appendMessage(role, text, cls) {
                const div = document.createElement('div');
                div.className = 'ai-msg ' + (cls || role); div.textContent = text;
                msgs.appendChild(div); msgs.scrollTop = msgs.scrollHeight; return div;
            }
            function appendUserMessage(text, imgUrl) {
                const div = document.createElement('div'); div.className = 'ai-msg user';
                if (text) { const t = document.createElement('div'); t.textContent = text; div.appendChild(t); }
                if (imgUrl) {
                    const im = document.createElement('img'); im.className = 'ai-msg-img'; im.src = imgUrl;
                    im.addEventListener('click', () => openOverlay(imgUrl));
                    div.appendChild(im);
                }
                msgs.appendChild(div); msgs.scrollTop = msgs.scrollHeight; return div;
            }
            function appendTyping() {
                const div = document.createElement('div'); div.className = 'ai-msg typing';
                div.innerHTML = '<span class="dot"></span><span class="dot"></span><span class="dot"></span>';
                msgs.appendChild(div); msgs.scrollTop = msgs.scrollHeight; return div;
            }

            titleInput.addEventListener('blur', () => {
                const s = getActive(); if (!s) return;
                const v = titleInput.value.trim() || '新對話';
                if (v !== s.title) { s.title = v; saveSessions(); renderSessionList(); }
            });
            titleInput.addEventListener('keydown', e => { if (e.key === 'Enter') { e.preventDefault(); titleInput.blur(); } });

            function open() { panel.hidden = false; bubble.classList.add('open'); renderSessionList(); renderActiveSession(); setTimeout(() => input.focus(), 0); }
            function close() { panel.hidden = true; bubble.classList.remove('open'); }
            bubble.addEventListener('click', () => panel.hidden ? open() : close());
            closeBtn.addEventListener('click', close);
            newChatBtn.addEventListener('click', () => { if (!busy) createSession(true); });

            // ---- Image attach ----
            function downsizeImage(dataUrl) {
                return new Promise(resolve => {
                    const img = new Image();
                    img.onload = () => {
                        const MAX = 1024; const longest = Math.max(img.width, img.height);
                        if (longest <= MAX) return resolve(dataUrl);
                        const ratio = MAX / longest;
                        const w = Math.round(img.width * ratio), h = Math.round(img.height * ratio);
                        const c = document.createElement('canvas'); c.width = w; c.height = h;
                        c.getContext('2d').drawImage(img, 0, 0, w, h);
                        try { resolve(c.toDataURL('image/jpeg', 0.85)); } catch (e) { resolve(dataUrl); }
                    };
                    img.onerror = () => resolve(dataUrl);
                    img.src = dataUrl;
                });
            }
            function approxKB(dataUrl) {
                const i = dataUrl.indexOf(',');
                const b64 = i >= 0 ? dataUrl.slice(i + 1) : dataUrl;
                return Math.round((b64.length * 3 / 4) / 1024);
            }
            function setAttachedFromFile(file) {
                if (!file || !file.type || file.type.indexOf('image/') !== 0) return;
                if (file.size > 20*1024*1024) { alert('圖片太大 (>20MB)'); return; }
                const reader = new FileReader();
                reader.onload = async () => {
                    const small = await downsizeImage(reader.result);
                    attachedImage = small;
                    previewImg.src = small;
                    previewMeta.textContent = '已附圖 (' + approxKB(small) + ' KB)';
                    previewBox.hidden = false;
                    input.focus();
                };
                reader.readAsDataURL(file);
            }
            function clearAttachment() { attachedImage = null; previewBox.hidden = true; previewImg.removeAttribute('src'); previewMeta.textContent = ''; }
            attachBtn.addEventListener('click', () => fileInput.click());
            fileInput.addEventListener('change', () => { const f = fileInput.files && fileInput.files[0]; fileInput.value = ''; if (f) setAttachedFromFile(f); });
            previewRemove.addEventListener('click', clearAttachment);
            previewImg.addEventListener('click', () => { if (previewImg.src) openOverlay(previewImg.src); });
            input.addEventListener('paste', ev => {
                const items = (ev.clipboardData && ev.clipboardData.items) || [];
                for (const it of items) {
                    if (it.kind === 'file' && it.type && it.type.indexOf('image/') === 0) {
                        const blob = it.getAsFile();
                        if (blob) { ev.preventDefault(); setAttachedFromFile(blob); return; }
                    }
                }
            });

            // ---- Send ----
            async function send() {
                if (busy) return;
                const text = input.value.trim();
                const img = attachedImage;
                if (!text && !img) return;
                const s = getActive(); if (!s) return;

                let userContent, displayText = text;
                if (img) {
                    if (!displayText) displayText = '請看這張圖';
                    userContent = [
                        { type: 'text', text: displayText },
                        { type: 'image_url', image_url: { url: img } }
                    ];
                } else { userContent = text; }

                input.value = '';
                clearAttachment();
                if (s.history.length === 0) maybeAutoTitle(s, displayText);
                appendUserMessage(displayText, img);
                s.history.push({ role: 'user', content: userContent });
                saveSessions(); renderSessionList();
                busy = true; sendBtn.disabled = true;
                const typing = appendTyping();
                try {
                    const res = await fetch(PROXY_URL, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json; charset=utf-8' },
                        body: JSON.stringify({ messages: s.history })
                    });
                    const data = await res.json();
                    typing.remove();
                    if (!res.ok || data.ok === false) {
                        const err = (data && (data.error || data.detail)) || ('HTTP ' + res.status);
                        appendMessage('assistant', '錯誤: ' + err, 'error');
                        s.history.pop(); saveSessions(); return;
                    }
                    const reply = (data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content) || '(空回應)';
                    appendMessage('assistant', reply);
                    s.history.push({ role: 'assistant', content: reply });
                    saveSessions();
                } catch (e) {
                    typing.remove();
                    appendMessage('assistant', '網路錯誤: ' + e.message, 'error');
                    s.history.pop(); saveSessions();
                } finally { busy = false; sendBtn.disabled = false; input.focus(); }
            }
            sendBtn.addEventListener('click', send);
            input.addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } });

            // ---- Boot ----
            loadSessions(); renderSessionList();
        })();
    </script>
</body>
</html>
