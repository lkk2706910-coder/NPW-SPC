<%@ Page Language="C#" AutoEventWireup="true" Inherits="NPW_Alarm" CodeFile="NPW_Alarm.aspx.cs" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>TF2 NPW Alarm 週報</title>
    <script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
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
        .save-status { margin-left: 14px; font-size: 13px; font-weight: 600; white-space: nowrap; min-width: 70px; }
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
        .sched td .sched-chk { display: block; text-align: left; white-space: nowrap; cursor: pointer; line-height: 1.5; }
        .sched td .sched-chk input { margin: 0 4px 0 0; vertical-align: middle; }
        .sched td .sched-chk.chk-done { color: #15803d; background: #eafaf0; }
        .sched td:has(.sched-chk) { text-align: left; }
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
        <h1>TF2 NPW Alarm 週報（全機台）</h1>
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
        .npw-report-card .entity-cell{cursor:pointer;color:#1d4ed8;text-decoration:underline;}
        .npw-report-card .rhrl-cell.rhrl-link{cursor:pointer;color:#1d4ed8;text-decoration:underline;font-weight:700;}
        .npw-modal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:10000;}
        .npw-modal.open{display:block;}
        .npw-modal-box{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);background:#fff;color:#111;border-radius:6px;max-width:94vw;max-height:88vh;display:flex;flex-direction:column;overflow:hidden;box-shadow:0 8px 30px rgba(0,0,0,.4);}
        .npw-modal-head{display:flex;align-items:center;justify-content:space-between;gap:24px;background:#2c5fa8;color:#fff;padding:8px 14px;}
        .npw-modal-head b{font-size:14px;}
        .npw-modal-head button{background:transparent;border:0;color:#fff;font-size:16px;cursor:pointer;line-height:1;}
        .npw-modal-body{padding:10px 14px;overflow:auto;}
        .npw-modal-body table{border-collapse:collapse;font-size:13px;width:100%;}
        .npw-modal-body th,.npw-modal-body td{border:1px solid #ccc;padding:5px 9px;text-align:left;white-space:nowrap;}
        .npw-modal-body th{background:#f0f0f0;}
        .npw-modal-body a{color:#1d4ed8;}
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
                    <col class="statS"><col class="statS"><col class="statM"><col class="statS"><col class="statS">
                    <col class="statS"><col class="statS"><col class="statM"><col class="statM">
                </colgroup>
                <thead>
                    <tr><th class="section-title" colspan="17">ADDER</th></tr>
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
                        <th class="h-amber">RHRL</th>
                        <th class="h-amber">Over Weekly to<br/>Day Count</th>
                        <th class="h-amber">Weekly to<br/>Day Target</th>
                        <th class="h-amber">Weekly<br/>Target Count</th>
                        <th class="h-amber">Alarm<br/>rate</th>
                        <th class="h-amber">Weekly<br/>Target Rate</th>
                        <th class="h-amber">Total Monitor<br/>Count</th>
                        <th class="h-amber">Owner</th>
                    </tr>
                </thead>
                <tbody></tbody>
                <tfoot>
                    <tr>
                        <td class="total-label" colspan="8">Total Alarm</td>
                        <td id="adderTotalAlarm">0</td>
                        <td></td>
                        <td class="total-good" colspan="2" id="adderTotalAlarmRate">0%</td>
                        <td></td><td></td>
                        <td class="total-warn" colspan="2" id="adderTotalWeeklyTargetRate">0%</td>
                        <td></td>
                    </tr>
                </tfoot>
            </table>
            </div>

            <!-- ========== NON-ADDER ========== -->
            <div class="report-scroll">
            <table class="report" id="tblNonAdder">
                <colgroup>
                    <col class="entity">
                    <col class="date"><col class="date"><col class="date"><col class="date"><col class="date"><col class="date"><col class="date">
                    <col class="statS"><col class="statS"><col class="statM"><col class="statS"><col class="statS">
                    <col class="statS"><col class="statS"><col class="statM"><col class="statM">
                </colgroup>
                <thead>
                    <tr><th class="section-title" colspan="17">NON-ADDER</th></tr>
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
                        <th class="h-amber">RHRL</th>
                        <th class="h-amber">Over Weekly to<br/>Day Count</th>
                        <th class="h-amber">Weekly to<br/>Day Target</th>
                        <th class="h-amber">Weekly<br/>Target Count</th>
                        <th class="h-amber">Alarm<br/>rate</th>
                        <th class="h-amber">Weekly<br/>Target Rate</th>
                        <th class="h-amber">Total Monitor<br/>Count</th>
                        <th class="h-amber">Owner</th>
                    </tr>
                </thead>
                <tbody></tbody>
                <tfoot>
                    <tr>
                        <td class="total-label" colspan="8">Total Alarm</td>
                        <td id="nonAdderTotalAlarm">0</td>
                        <td></td>
                        <td class="total-good" colspan="2" id="nonAdderTotalAlarmRate">0%</td>
                        <td></td><td></td>
                        <td class="total-warn" colspan="2" id="nonAdderTotalWeeklyTargetRate">0%</td>
                        <td></td>
                    </tr>
                </tfoot>
            </table>
            </div>
        </div>
    </div>

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

        // ===== Owner（依使用者提供）=====
        const OWNER_ADDER={APF:'瑋修',NISACVD:'宗瑋',SACVD:'宗瑋',TEOSPE:'瑋修',TTOX:'煒翔',CUTTOX:'煒翔',BLOKCVD:'瑋修',ULKCVD:'瑋修',CUSILPE:'添傑',CULKCVD:'添傑',DARC:'添傑',SILPE:'添傑',HKG:'建維',ALDOX:'建維',OXSE:'瑋修',HBWFBOND:'添傑',HBVOIDINP:'添傑'};
        const OWNER_NON_ADDER={APF:'瑋修/宗漢',NISACVD:'宗瑋/函原',SACVD:'宗瑋/芙潔',TEOSPE:'瑋修/蕭暘',TTOX:'煒翔/孟修',CUTTOX:'煒翔/建賢',BLOKCVD:'瑋修/映臻',ULKCVD:'瑋修/勇叡',CUSILPE:'添傑/裕和',CULKCVD:'添傑/祈綸',DARC:'添傑/孟修',SILPE:'添傑/裕和',HKG:'建維/建志',ALDOX:'建維/怡婷',OXSE:'瑋修/嘉琦'};
        function getOwner(e,isAdder){const t=isAdder?OWNER_ADDER:OWNER_NON_ADDER;return t[e]!=null?t[e]:'';}

        // ===== RHRL（讀同資料夾 TF2 RHRL.xlsx）=====
        let rhrlRows=[];   // 本週 RH/RL 原始列（供明細）
        async function loadRhrl(picked){
            rhrlRows=[];
            if(typeof XLSX==='undefined')return;
            try{
                const res=await fetch(encodeURI('TF2 RHRL.xlsx'),{cache:'no-store'});
                if(!res.ok)return;
                const wb=XLSX.read(new Uint8Array(await res.arrayBuffer()),{type:'array',cellDates:true});
                const ws=wb.Sheets[wb.SheetNames[0]];
                const rows=XLSX.utils.sheet_to_json(ws,{defval:null});
                if(!rows.length)return;
                const keys=Object.keys(rows[0]);
                const norm=k=>String(k).toLowerCase().replace(/\s+/g,'');
                const kDate=keys.find(k=>norm(k)==='date')||keys.find(k=>norm(k).includes('date'));
                const kOhol=keys.find(k=>/oh\s*or\s*ol/i.test(k))||keys.find(k=>norm(k).includes('ohorol'))||keys.find(k=>/rhrl/i.test(k));
                const kEqp=keys.find(k=>/eqp\s*id/i.test(k))||keys.find(k=>norm(k).includes('eqpid'));
                const kName=keys.find(k=>/chart\s*name/i.test(k))||keys.find(k=>norm(k).includes('measequipment'))||keys.find(k=>norm(k).includes('chartname'));
                const kChartId=keys.find(k=>/chart\s*id/i.test(k))||keys.find(k=>norm(k).includes('kqfid'))||keys.find(k=>norm(k).includes('chartid'));
                const kTrack=keys.find(k=>String(k).includes('是否需'))||keys.find(k=>/lot\s*tracking/i.test(k)&&!/原因|reason/i.test(k));
                const kReason=keys.find(k=>/原因/.test(k))||keys.find(k=>/reason/i.test(k));
                if(!kDate||!kOhol||!kEqp)return;
                const start=startTuesdayFor(picked);
                const days=new Set();for(let i=0;i<7;i++){const d=new Date(start.getFullYear(),start.getMonth(),start.getDate()+i);days.add(fmtYMDDash(d));}
                const md=ds=>{const p=ds.split('-');return p.length===3?(p[1]+'/'+p[2]):ds;};
                rows.forEach(r=>{
                    const dv=r[kDate];let ds;
                    if(dv instanceof Date)ds=fmtYMDDash(dv);
                    else{const jd=new Date(dv);ds=isNaN(jd.getTime())?String(dv||'').substring(0,10):fmtYMDDash(jd);}
                    if(!days.has(ds))return;
                    const oh=String(r[kOhol]||'').trim().toUpperCase();
                    if(oh!=='RH'&&oh!=='RL')return;
                    const eqp=String(r[kEqp]||'').trim();
                    rhrlRows.push({
                        ds:ds, dateDisp:md(ds),
                        chartName:kName?String(r[kName]||''):'',
                        chartId:kChartId?String(r[kChartId]==null?'':r[kChartId]):'',
                        eqp:eqp, eqpU:eqp.toUpperCase(), ohol:oh,
                        track:kTrack?String(r[kTrack]==null?'':r[kTrack]):'',
                        reason:kReason?String(r[kReason]||''):''
                    });
                });
            }catch(e){console.error('RHRL load',e);}
        }
        function rhrlDetailFor(entity){const E=String(entity).toUpperCase();return rhrlRows.filter(r=>r.eqpU.indexOf(E)===0);}
        function rhrlCountFor(entity){return rhrlDetailFor(entity).length;}

        // 圖表連結 + 明細彈窗
        function buildChartUrl(chartId){if(!chartId)return null;return 'http://10.10.101.170/projectsite/SPCTool/PreviewMultiSPCTypeChart.aspx?site=12AP58&ChartList=NPW:'+encodeURIComponent(chartId);}
        function mEsc(v){return String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
        function mLink(name,chartId){const u=buildChartUrl(chartId);return u?'<a href="'+mEsc(u)+'" target="_blank" rel="noopener noreferrer">'+mEsc(name)+'</a>':mEsc(name);}
        function openModal(title,html){document.getElementById('npwModalTitle').textContent=title;document.getElementById('npwModalBody').innerHTML=html;document.getElementById('npwModal').classList.add('open');}
        function closeModal(){document.getElementById('npwModal').classList.remove('open');}
        function curPicked(){const iv=document.getElementById('pickDate');return (iv&&iv.value)?new Date(iv.value+'T00:00:00'):new Date();}
        function openAlarmDetail(entity,isAdder){
            const start=startTuesdayFor(curPicked());
            const key=fmtYMDDash(start)+'|'+entity+'|'+(isAdder?'ADDER':'NON_ADDER');
            const cm=chartAlarmStats[key]||{};
            let body='';
            Object.keys(cm).forEach(ck=>{const a=ck.split('||');body+='<tr><td>'+mEsc(a[0])+'</td><td>'+mLink(a[1],a[0])+'</td><td style="text-align:center">'+cm[ck]+'</td></tr>';});
            if(!body)body='<tr><td colspan="3" style="color:#888">本週無 alarm</td></tr>';
            openModal((isAdder?'ADDER':'NON-ADDER')+' - '+entity+' - Alarm Detail (W'+getWeekNumber(start)+')',
                '<table><thead><tr><th>CHART_ID</th><th>CHART_NAME</th><th>Alarm 次數</th></tr></thead><tbody>'+body+'</tbody></table>');
        }
        function openRhrlDetail(entity){
            const start=startTuesdayFor(curPicked());
            const list=rhrlDetailFor(entity);
            let body='';
            list.forEach(r=>{body+='<tr><td>'+mEsc(r.dateDisp)+'</td><td>'+mLink(r.chartName,r.chartId)+'</td><td>'+mEsc(r.chartId)+'</td><td>'+mEsc(r.eqp)+'</td><td style="text-align:center">'+mEsc(r.ohol)+'</td><td style="text-align:center">'+mEsc(r.track)+'</td><td>'+mEsc(r.reason)+'</td></tr>';});
            if(!body)body='<tr><td colspan="7" style="color:#888">本週無 RH/RL</td></tr>';
            openModal('RHRL - '+entity+' - Detail (W'+getWeekNumber(start)+')',
                '<table><thead><tr><th>Date</th><th>Chart Name</th><th>Chart ID</th><th>EQP ID</th><th>OH or OL?</th><th>是否需 lot tracking ?</th><th>不需 lot tracking 的原因 ?</th></tr></thead><tbody>'+body+'</tbody></table>');
        }

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

                // Alarm Counts (td8)
                const alarmTd=tds[8];
                alarmTd.textContent=alarmCount?String(alarmCount):'0';

                // RHRL (td9) — 本週 RH/RL 次數，>0 粉紅標記、可點開明細
                const rhrl=rhrlCountFor(entity);
                const rhrlTd=tds[9];
                rhrlTd.textContent=rhrl?String(rhrl):'0';
                if(rhrl>0)rhrlTd.classList.add('alarm-over-target');else rhrlTd.classList.remove('alarm-over-target');
                rhrlTd.classList.toggle('rhrl-link',rhrl>0);

                // Weekly Target Count
                const weeklyTargetCount=getWeeklyTargetCount(entity,isAdder);
                // Weekly to Day Target = Weekly Target Count * (今天是第幾天 / 7)
                let weeklyToDayTarget=0;
                if(dayOfRange>0)weeklyToDayTarget=Math.round(weeklyTargetCount*(dayOfRange/7));

                // Over Weekly to Day Count (td10, barcell)
                const overTd=tds[10];
                const txt=overTd.querySelector('.txt');
                const overCount=Math.max(0,alarmCount-weeklyToDayTarget);
                txt.textContent=overCount?String(overCount):'0';
                let widthPercent=0;
                if(overCount>0)widthPercent=Math.min(100,overCount*10);
                overTd.style.setProperty('--w',widthPercent+'%');

                // Weekly to Day Target (td11) & Weekly Target Count (td12)
                tds[11].textContent=weeklyToDayTarget?String(weeklyToDayTarget):'0';
                tds[12].textContent=weeklyTargetCount?String(weeklyTargetCount):'0';

                // Alarm rate (td13)
                let alarmRate=0;
                if(totalMonitor>0)alarmRate=alarmCount/totalMonitor;
                tds[13].textContent=(alarmRate*100).toFixed(2)+'%';

                // Weekly Target Rate (td14)
                tds[14].textContent=getWeeklyTargetRate(entity,isAdder).toFixed(2)+'%';

                // Total Monitor Count (td15)
                tds[15].textContent=totalMonitor?String(totalMonitor):'0';

                // Owner (td16)
                tds[16].textContent=getOwner(entity,isAdder);

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
                const g=cells[3],y=cells[6];
                if(g&&y){
                    const gv=parseFloat(g.textContent.replace('%','').trim())||0;
                    const yv=parseFloat(y.textContent.replace('%','').trim())||0;
                    if(gv>yv)g.classList.add('total-green-over-yellow');else g.classList.remove('total-green-over-yellow');
                }
            }
        }

        let _lastStats=null;
        // 全機台：entity = 資料內出現的 + 目標表內列的，去重排序
        function allEntities(stats){
            const set={};
            Object.keys(stats||{}).forEach(e=>set[e]=1);
            Object.keys(WEEKLY_TARGET_ADDER).forEach(e=>set[e]=1);
            Object.keys(WEEKLY_TARGET_NON_ADDER).forEach(e=>set[e]=1);
            return Object.keys(set).sort();
        }
        function buildEntityRows(tableId,entities){
            const tb=document.querySelector('#'+tableId+' tbody');
            if(!tb)return;
            tb.innerHTML=entities.map(e=>{
                const ee=String(e).replace(/&/g,'&amp;').replace(/</g,'&lt;');
                return '<tr data-entity="'+ee+'">'
                    +'<td class="left entity-cell">'+ee+'</td>'
                    +'<td></td><td></td><td></td><td></td><td></td><td></td><td></td>'
                    +'<td>0</td>'
                    +'<td class="rhrl-cell">0</td>'
                    +'<td class="barcell"><span class="bar"></span><span class="txt">0</span></td>'
                    +'<td>0</td><td>0</td>'
                    +'<td>0%</td><td>0%</td><td>0</td>'
                    +'<td class="left"></td>'
                    +'</tr>';
            }).join('');
        }
        function refreshTables(picked){
            const {stats,days}=buildStats(picked);
            _lastStats=stats;
            const entities=allEntities(stats);
            buildEntityRows('tblAdder',entities);
            buildEntityRows('tblNonAdder',entities);
            updateTableByStats('tblAdder',stats,days,true,picked);
            updateTableByStats('tblNonAdder',stats,days,false,picked);
        }

        function fmtMD(d){return String(d.getMonth()+1).padStart(2,'0')+'/'+String(d.getDate()).padStart(2,'0');}


        // ===== 初始化 =====
        (function init(){
            const input=document.getElementById('pickDate');
            const weekHint=document.getElementById('weekHint');
            function updateWeekHint(d){weekHint.textContent='W'+getWeekNumber(startTuesdayFor(d));}

            const today=new Date();
            input.value=toISODateLocal(today);
            setHeadersByPickedDate(today);
            updateWeekHint(today);

            async function reload(picked){
                setHeadersByPickedDate(picked);
                updateWeekHint(picked);
                try{await loadFromDb(picked);await loadRhrl(picked);refreshTables(picked);}catch(e){/* 已顯示 */}
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

            // 點 Entity → alarm 明細；點 RHRL 數值 → RH/RL 明細；關閉彈窗（事件委派，不依賴元素已存在）
            document.addEventListener('click',e=>{
                if(e.target.closest('#npwModalClose')){closeModal();return;}        // ✕
                const modal=document.getElementById('npwModal');
                if(modal&&e.target===modal){closeModal();return;}                   // 點黑底
                const ec=e.target.closest('.entity-cell');
                if(ec){const tbl=ec.closest('table.report'),tr=ec.closest('tr[data-entity]');if(tbl&&tr){openAlarmDetail(tr.getAttribute('data-entity'),tbl.id==='tblAdder');return;}}
                const rc=e.target.closest('.rhrl-cell.rhrl-link');
                if(rc){const tr=rc.closest('tr[data-entity]');if(tr){openRhrlDetail(tr.getAttribute('data-entity'));return;}}
            });
            document.addEventListener('keydown',e=>{if(e.key==='Escape')closeModal();});

            reload(today);
        })();
    })();
    </script>

    <div id="npwModal" class="npw-modal">
        <div class="npw-modal-box">
            <div class="npw-modal-head"><b id="npwModalTitle">Detail</b><button id="npwModalClose" type="button">&#10005;</button></div>
            <div class="npw-modal-body" id="npwModalBody"></div>
        </div>
    </div>
</body>
</html>
