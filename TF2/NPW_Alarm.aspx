<%@ Page Language="C#" AutoEventWireup="true" Inherits="NPW_Alarm" CodeFile="NPW_Alarm.aspx.cs" EnableSessionState="false" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>TF2 NPW Alarm 日報</title>
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
        <h1>TF2 NPW</h1>
        <div class="seg-tabs">
        </div>
        <span id="saveStatus" class="save-status"></span>
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
        .emst-btn{padding:4px 12px;border:1px solid #1976d2;border-radius:6px;background:#fff;color:#1976d2;font-size:12px;font-weight:700;cursor:pointer;}
        .emst-btn:hover{background:#1976d2;color:#fff;}
        /* ===== EMST 明細彈窗（版面參考 OCAP.aspx 明細頁；所有規則皆以 #emstModal 限定，避免與本頁 .card 等衝突）===== */
        #emstModal{display:none;position:fixed;inset:0;z-index:1190;background:rgba(15,23,42,.55);align-items:flex-start;justify-content:center;padding:24px 16px;overflow:auto;}
        #emstModal .em-modal{background:#fff;border-radius:12px;width:100%;max-width:1400px;box-shadow:0 24px 64px rgba(2,6,23,.35);overflow:hidden;color:#26303d;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Noto Sans TC",Arial,sans-serif;}
        #emstModal .em-head{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:12px 18px;background:linear-gradient(135deg,#1e88e5,#1565c0);color:#fff;}
        #emstModal .em-head h3{margin:0;font-size:16px;font-weight:600;word-break:break-all;}
        #emstModal .em-head .sub{font-size:12px;opacity:.9;}
        #emstModal .em-head .block{display:inline-block;font-size:11px;font-weight:700;letter-spacing:.5px;padding:1px 8px;border-radius:999px;margin-right:8px;vertical-align:middle;background:rgba(255,255,255,.22);color:#fff;}
        #emstModal .em-head .block.non-adder{background:#ffd54f;color:#4a3200;}
        #emstModal .em-close{background:transparent;border:0;color:#fff;font-size:26px;line-height:1;padding:0 4px;cursor:pointer;}
        #emstModal .em-close:hover{background:rgba(255,255,255,.15);}
        #emstModal .em-body{padding:16px 18px 20px;}
        #emstModal .info-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:10px 18px;margin-bottom:16px;}
        #emstModal .info-grid .k{font-size:11px;color:#6b7684;letter-spacing:.3px;}
        #emstModal .info-grid .v{font-size:13px;color:#26303d;word-break:break-all;min-height:20px;}
        #emstModal .info-grid .v.pending{color:#98a2b3;}
        #emstModal .info-grid .wide{grid-column:span 2;}
        #emstModal .wc-line{display:flex;gap:8px;align-items:baseline;font-size:12px;white-space:nowrap;}
        #emstModal .wc-line .wc-eq{font-family:Consolas,"Courier New",monospace;color:#45505f;min-width:128px;}
        #emstModal .wc-line .wc-meter{color:#6b7684;min-width:120px;}
        #emstModal .wc-line .wc-val{font-weight:600;}
        #emstModal .wc-line .wc-spec{color:#6b7684;}
        #emstModal .wc-line.hit .wc-eq{color:#1565c0;font-weight:600;}
        #emstModal .wc-line.over .wc-val{color:#c62828;}
        #emstModal .wc-note{font-size:11px;color:#98a2b3;margin-top:4px;}
        #emstModal .detail-grid{display:grid;grid-template-columns:minmax(0,1.5fr) minmax(0,1fr) minmax(0,1fr);gap:14px;}
        #emstModal .detail-grid.non-adder{grid-template-columns:minmax(0,1.5fr) minmax(0,1fr);}
        @media (max-width:960px){#emstModal .detail-grid,#emstModal .detail-grid.non-adder{grid-template-columns:1fr;}}
        #emstModal .em-card{border:1px solid #e3e8ef;border-radius:10px;padding:12px;background:#fff;display:flex;flex-direction:column;min-width:0;}
        #emstModal .em-card h4{margin:0 0 8px;font-size:13px;font-weight:600;color:#45505f;display:flex;align-items:center;justify-content:space-between;gap:8px;}
        #emstModal .em-card h4 small{font-weight:400;color:#98a2b3;font-size:11px;}
        #emstModal .spark{position:relative;width:100%;height:320px;}
        #emstModal .spark canvas{display:block;width:100% !important;height:100% !important;}
        #emstModal .map-box{display:flex;align-items:center;justify-content:center;min-height:320px;background:#fafbfd;border:1px dashed #dfe5ee;border-radius:8px;color:#98a2b3;font-size:13px;text-align:center;padding:8px;}
        #emstModal .map-box img{max-width:100%;max-height:420px;width:auto;display:block;border:1px solid #cfd7e3;background:#fff;margin:0 auto;}
        #emstModal .map-hint{font-size:11px;color:#98a2b3;margin-top:6px;text-align:center;}
        #emstModal .emst{margin-top:14px;}
        #emstModal .emst-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px 14px;}
        @media (max-width:960px){#emstModal .emst-grid{grid-template-columns:1fr;}}
        #emstModal .emst-grid label{display:flex;flex-direction:column;gap:4px;font-size:12px;color:#6b7684;}
        #emstModal .emst-grid label.full{grid-column:1 / -1;}
        #emstModal .emst-grid input,#emstModal .emst-grid textarea{font:inherit;font-size:13px;padding:7px 10px;border:1px solid #cfd7e3;border-radius:6px;color:#26303d;background:#fff;}
        #emstModal .emst-grid textarea{resize:vertical;min-height:64px;}
        #emstModal .emst-grid input:focus,#emstModal .emst-grid textarea:focus{outline:none;border-color:#1e88e5;box-shadow:0 0 0 3px rgba(30,136,229,.12);}
        #emstModal .emst-actions{display:flex;align-items:center;gap:10px;margin-top:10px;flex-wrap:wrap;}
        #emstModal .emst-actions button{padding:7px 14px;border:0;border-radius:6px;background:#1e88e5;color:#fff;font-weight:600;cursor:pointer;}
        #emstModal .emst-actions button.ghost{background:#fff;color:#1e88e5;border:1px solid #cfd7e3;}
        #emstModal .emst-actions button.ghost:hover{background:#f0f6fd;}
        #emstModal .emst-actions button:disabled{opacity:.6;cursor:default;}
        #emstModal .status{font-size:13px;color:#6b7684;margin-left:auto;}
        #emstModal .status.error{color:#c62828;}
        #emstModal .status.ok{color:#2e7d32;}
        .npw-report-card .dup-chart{background:#ffe19a!important;}
        .npw-report-card .dim-row{background:#d9d9d9!important;}
        .npw-report-card .inline-empty{padding:8px 10px;color:#666;font-size:12px;background:#fff;border:1px dashed #999;}
        </style>
        <section id="sec-weekly">
        <div class="card npw-report-card">
            <div class="npw-toolbar">
                <h2 style="margin:0;">NPW Alarm 日報</h2>
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

            <div id="adderChartDetail"></div>

            <div id="nonAdderChartDetail"></div>
        </div>
        </section>
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
        // 資料區間改為「每日」：起點即所選日期本身（原為該週的週二）。
        // 後端 op=alarm / op=port 也改為單日範圍，其餘沿用週版的迴圈皆無害。
        function startTuesdayFor(sel){return new Date(sel.getFullYear(),sel.getMonth(),sel.getDate());}
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
        let chartPort={};      // key|chartKey -> Set(PORTID)（來自 ews_lothist，背景載入）
        let chartMon={};       // key|chartKey -> Set(MONITOR_TYPE)（欄位顯示用）
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
            chartAlarmStats={};chartAlarmDateStats={};chartMeasurePu={};chartAlarmSeq={};chartProcUnit={};chartAlarmMean={};chartAlarmWafer={};chartParameter={};chartPort={};chartMon={};
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

                // Total Monitor Count（MONITOR_TYPE=NORMAL/PM 且非 Engineering）
                if((MT==='NORMAL'||MT==='PM')&&!isEng){
                    if(CT==='C-C'){ds.totalMonAdder+=MON;es.sum.totalMonAdder+=MON;}
                    else if(CT==='XBAR'){ds.totalMonNonAdder+=MON;es.sum.totalMonNonAdder+=MON;}
                }

                // Alarm 條件（MONITOR_TYPE 改為 all，不再篩選；型別另以欄位顯示）
                // DOWN 紀錄的 ALARM_COUNT 多為 0，但仍要列出：DOWN 一律視為要顯示的列
                if(!(alarmCnt>=1)&&MT!=='DOWN')continue;
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
                {const mk=key+'|'+ck;if(!chartMon[mk])chartMon[mk]=new Set();if(MT)chartMon[mk].add(MT);}
                if(row.MEASUREPU!=null&&String(row.MEASUREPU).trim()!=='')chartMeasurePu[key+'|'+ck]=String(row.MEASUREPU);
                if(row.PROCESSUNIT!=null)chartProcUnit[key+'|'+ck]=String(row.PROCESSUNIT);
                {const plk=_portLookup[String(row.LOT||'')+'|'+ut+'|'+(isAdder?'A':'N')];if(plk&&plk.size){const pk=key+'|'+ck;if(!chartPort[pk])chartPort[pk]=new Set();plk.forEach(p=>chartPort[pk].add(p));}}
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
            if(!tbl)return;  // 計數表格已移除，安全略過
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

        let _lastStats=null;
        // ===== Port 背景載入（op=port）=====
        // Port 的跨庫查詢較慢，改為與主查詢平行、不阻塞頁面渲染：
        // 主表先顯示（Port 欄為 ...），查詢回來後就地填入格子，不重繪表格。
        let _portLookup={};      // 'LOT|yyyy-mm-dd' -> Set(PORTID)
        let _portsLoading=false;
        let _portSeq=0;          // 防止換週後舊回應覆蓋新資料
        async function loadPorts(picked){
            const seq=++_portSeq;
            _portLookup={};_portsLoading=true;
            try{
                const qs=new URLSearchParams({op:'port',date:toISODateLocal(picked)});
                const res=await fetch(PAGE+'?'+qs.toString(),{cache:'no-store'});
                const data=await res.json();
                if(seq!==_portSeq)return;
                if(data.ok)for(const r of (data.rows||[])){
                    // key 含 BLK（A=ADDER/N=NON-ADDER）：NON-ADDER 只用 LOTID+日期對應
                    //（不比 RECIPE/PPID），同一 LOT 同日兩區塊的 port 集合可能不同
                    const k=String(r.LOT||'')+'|'+String(r.UPDATE_TIME||'')+'|'+String(r.BLK||'A');
                    const p=String(r.PORTID==null?'':r.PORTID).trim();
                    if(!p)continue;
                    if(!_portLookup[k])_portLookup[k]=new Set();
                    _portLookup[k].add(p);
                }
            }catch(e){/* 查不到就留空 */}
            if(seq!==_portSeq)return;
            _portsLoading=false;
            applyPorts(picked);
        }
        // 依 rawData + _portLookup 重建 chartPort（與 buildStats 同樣的列篩選）
        function rebuildChartPort(picked){
            chartPort={};
            const start=startTuesdayFor(picked);
            const days=[];for(let i=0;i<7;i++){const d=new Date(start.getFullYear(),start.getMonth(),start.getDate());d.setDate(start.getDate()+i);days.push(fmtYMDDash(d));}
            const entOf=pu=>{if(!pu)return null;const s=String(pu).toUpperCase();const i=s.indexOf('-');return i===-1?s:s.substring(0,i);};
            for(const row of rawData){
                const entity=entOf(row.PROCESSUNIT);if(!entity)continue;
                let ut=row.UPDATE_TIME;if(!ut)continue;
                if(typeof ut==='string'){ut=ut.substring(0,10);}else{const j=new Date(ut);if(isNaN(j.getTime()))continue;ut=fmtYMDDash(j);}
                if(!days.includes(ut))continue;
                if(!(Number(row.ALARM_COUNT)>=1)&&String(row.MONITOR_TYPE||'').toUpperCase()!=='DOWN')continue;
                if(String(row.CHART_DESC||'').trim().toUpperCase()==='ENGINEERING')continue;
                const CT=String(row.CHART_TYPE||'').trim().toUpperCase();
                let isAdder;if(CT==='C-C')isAdder=true;else if(CT==='XBAR')isAdder=false;else continue;
                const plk=_portLookup[String(row.LOT||'')+'|'+ut+'|'+(isAdder?'A':'N')];
                if(!plk||!plk.size)continue;
                const pk=fmtYMDDash(start)+'|'+entity+'|'+(isAdder?'ADDER':'NON_ADDER')+'|'+(row.CHART_ID||'')+'||'+(row.CHART_NAME||'');
                if(!chartPort[pk])chartPort[pk]=new Set();
                plk.forEach(p=>chartPort[pk].add(p));
            }
        }
        // 把 chartPort 值就地填入 Port 欄（不重繪表格、不重載圖）
        function applyPorts(picked){
            rebuildChartPort(picked);
            document.querySelectorAll('td.port-cell').forEach(td=>{
                const s=chartPort[td.getAttribute('data-pk')];
                td.textContent=(s&&s.size)?Array.from(s).sort().join(', '):(_portsLoading?'...':'');
            });
        }

        function refreshTables(picked){
            const {stats,days}=buildStats(picked);
            _lastStats=stats;
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
        const ITEM_ORDER=['HTSIN130_11','PEOX50A','5.5K','USG50','CHC 2K','DAILY2_PA','DAILY4_PA','D2_PA','D4_PA','DAILY_PA','FSPA','XFER','Weekly PA'];
        function itemRank(t){const i=ITEM_ORDER.indexOf(t);return i<0?ITEM_ORDER.length-0.5:i;}
        const SCHEDULE=[
            { title:'NISACVD', rows:[
                { name:'NISACVD-B01', shift:'日', ev:[ {items:'Weekly PA',every:7,from:'2026-06-17'}, {items:'XFER',every:2,from:'2026-06-17'}, {items:'HTSIN130_11+PEOX50A',every:3,from:'2026-06-17'} ] },
                { name:'NISACVD-B06', shift:'日', ev:[ {items:'HTSIN130_11+PEOX50A+XFER',every:3,from:'2026-06-16'}, {items:'Weekly PA',every:7,from:'2026-06-16'} ] },
                { name:'NISACVD-B07', shift:'日', ev:[ {items:'HTSIN130_11+PEOX50A+XFER',every:3,from:'2026-06-16'}, {items:'Weekly PA',every:7,from:'2026-06-18'} ] },
                { name:'NISACVD-B08', shift:'夜', ev:[ {items:'HTSIN130_11+PEOX50A+XFER',every:3,from:'2026-06-17'}, {items:'Weekly PA',every:7,from:'2026-06-21'} ] },
                { name:'NISACVD-B03', shift:'夜', ev:[ {items:'XFER',every:3,from:'2026-06-16'}, {items:'DAILY_PA',every:3,from:'2026-06-17'} ] },
                { name:'NISACVD-B12', shift:'日', ev:[ {items:'XFER',every:3,from:'2026-06-17'}, {items:'DAILY_PA',every:3,from:'2026-06-17'} ] },
                { name:'NISACVD-B13', shift:'夜', ev:[ {items:'XFER',every:3,from:'2026-06-16'}, {items:'DAILY_PA',every:3,from:'2026-06-16'} ] },
                { name:'NISACVD-B14', shift:'日', ev:[ {items:'XFER',every:3,from:'2026-06-16'}, {items:'DAILY_PA',every:3,from:'2026-06-16'} ] },
                { name:'NISACVD-B02', shift:'夜', ev:[ {items:'XFER',every:3,from:'2026-08-17'}, {items:'FSPA',every:3,from:'2026-08-18'}, {items:'Weekly PA',every:7,from:'2026-08-14'} ] },
                { name:'NISACVD-B04', shift:'夜', ev:[ {items:'XFER',every:3,from:'2026-08-15'}, {items:'FSPA',every:3,from:'2026-08-17'}, {items:'Weekly PA',every:7,from:'2026-08-17'} ] },
                { name:'NISACVD-B05', shift:'日', ev:[ {items:'XFER',every:3,from:'2026-08-18'}, {items:'FSPA',every:3,from:'2026-08-18'}, {items:'Weekly PA',every:7,from:'2026-08-17'} ] },
                { name:'NISACVD-B09', shift:'夜', ev:[ {items:'XFER',every:3,from:'2026-08-17'}, {items:'FSPA',every:3,from:'2026-08-17'}, {items:'Weekly PA',every:7,from:'2026-08-17'} ] },
                { name:'NISACVD-B10', shift:'日', ev:[ {items:'XFER',every:3,from:'2026-08-19'}, {items:'FSPA',every:3,from:'2026-08-19'}, {items:'Weekly PA',every:7,from:'2026-08-17'} ] },
                { name:'NISACVD-B11', shift:'日', ev:[ {items:'XFER',every:3,from:'2026-08-17'}, {items:'FSPA',every:3,from:'2026-08-17'}, {items:'Weekly PA',every:7,from:'2026-08-18'} ] }
            ]},
            { title:'SACVD (5.5K)', rows:[
                { name:'SACVD-B01', shift:'日', ev:[ {items:'5.5K',every:3,from:'2026-06-17'}, {items:'XFER',every:3,from:'2026-06-17'} ] },
                { name:'SACVD-B04', shift:'夜', ev:[ {items:'5.5K',every:3,from:'2026-06-18'}, {items:'XFER',every:3,from:'2026-06-18'} ] },
                { name:'SACVD-B06', shift:'夜', ev:[ {items:'5.5K',every:3,from:'2026-06-16'}, {items:'XFER',every:3,from:'2026-06-16'} ] },
                { name:'SACVD-B08', shift:'日', ev:[ {items:'5.5K',every:3,from:'2026-06-18'}, {items:'XFER',every:3,from:'2026-06-18'} ] },
                { name:'SACVD-B09', shift:'日', ev:[ {items:'5.5K',every:3,from:'2026-06-16'}, {items:'XFER',every:3,from:'2026-06-16'} ] },
                { name:'SACVD-B10', shift:'日', ev:[ {items:'5.5K',every:3,from:'2026-06-16'}, {items:'XFER',every:3,from:'2026-06-16'} ] }
            ]},
            { title:'SACVD (USG50)', rows:[
                { name:'SACVD-B02', shift:'夜', ev:[ {items:'USG50',every:2,from:'2026-06-17'}, {items:'XFER',every:3,from:'2026-06-18'}, {items:'CHC 2K',every:3,from:'2026-06-18'} ] },
                { name:'SACVD-B11', shift:'日', ev:[ {items:'USG50',every:2,from:'2026-06-16'}, {items:'XFER',every:3,from:'2026-06-17'} ] },
                { name:'SACVD-B12', shift:'夜', ev:[ {items:'USG50',every:2,from:'2026-06-16'}, {items:'XFER',every:3,from:'2026-06-16'} ] }
            ]},
            { title:'SACVD-B03B / B03C / B07A 只測 SABOX110 PA', rows:[
                { name:'SACVD-B03', shift:'日', ev:[ {items:'XFER',every:3,from:'2026-06-18'}, {items:'DAILY2_PA',every:2,from:'2026-06-16'}, {items:'DAILY4_PA',every:4,from:'2026-06-16'} ] },
                { name:'SACVD-B05', shift:'夜', ev:[ {items:'XFER',every:3,from:'2026-06-16'}, {items:'D2_PA',every:2,from:'2026-06-17'}, {items:'D4_PA',every:4,from:'2026-06-19'} ] },
                { name:'SACVD-B07', shift:'夜', ev:[ {items:'XFER',every:3,from:'2026-06-17'}, {items:'D2_PA',every:2,from:'2026-06-16'}, {items:'D4_PA',every:4,from:'2026-06-18'} ] }
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
                return items;
            }
            return ((row.cells&&row.cells[idx])||'').split('\n').filter(Boolean);
        }
        // 勾選狀態：存在伺服器 JSON 檔，所有人共用；值為 {by,at} 記錄勾選人/時間
        let schedChecks={};
        let _schedPicked=null;
        let schedUser=(localStorage.getItem('npw.user')||'').trim();
        function ensureUser(){
            if(!schedUser){schedUser=((window.prompt('請輸入你的名字（用於記錄勾選人）')||'').trim());if(schedUser)localStorage.setItem('npw.user',schedUser);}
            return schedUser;
        }
        function checkMeta(v){
            if(v&&typeof v==='object')return (v.by?('勾選人：'+v.by):'勾選')+(v.at?('　時間：'+v.at):'');
            return v?'已勾選':'';
        }
        function applyChecksToDOM(){
            const box=document.getElementById('downSchedule');if(!box)return;
            box.querySelectorAll('input[type=checkbox][data-k]').forEach(cb=>{
                const v=schedChecks[cb.getAttribute('data-k')];
                cb.checked=!!v;
                const lbl=cb.closest('.sched-chk');
                if(lbl){lbl.title=checkMeta(v);lbl.classList.toggle('chk-done',!!v);}
            });
        }
        async function loadSchedChecksServer(){
            try{const r=await fetch(PAGE+'?op=getchecks',{cache:'no-store'});const d=await r.json();if(d&&d.ok)schedChecks=d.checks||{};}catch(e){}
            const box=document.getElementById('downSchedule');
            if(box&&box.querySelector('input[data-k]'))applyChecksToDOM();   // 已建表→只更新勾選(不重繪、不跳動)
            else if(_schedPicked)renderSchedule(_schedPicked);
        }
        let _saveTimer=null;
        function setSaveStatus(text,color,autoHide){
            const el=document.getElementById('saveStatus');
            if(!el)return;
            el.textContent=text||'';
            el.style.color=color||'#555';
            if(_saveTimer){clearTimeout(_saveTimer);_saveTimer=null;}
            if(autoHide)_saveTimer=setTimeout(()=>{el.textContent='';},2500);
        }
        async function saveSchedCheck(k,checked){
            const by=ensureUser();
            setSaveStatus('儲存中…','#b45309');
            try{
                const r=await fetch(PAGE+'?op=savecheck',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({key:k,checked:!!checked,by:by})});
                const d=await r.json().catch(()=>null);
                if(!r.ok||!d||!d.ok){
                    console.error('savecheck failed',r.status,d);
                    setSaveStatus('儲存失敗：'+((d&&d.error)?d.error:('HTTP '+r.status)),'#c00');
                }else{
                    if(checked)schedChecks[k]={by:by,at:(d.at||'')}; else delete schedChecks[k];
                    applyChecksToDOM();
                    setSaveStatus('已儲存 ✓'+(by?('（'+by+'）'):''),'#15803d',true);
                }
            }catch(e){console.error(e);setSaveStatus('儲存失敗：'+e.message,'#c00');}
        }
        function renderSchedule(picked){
            const box=document.getElementById('downSchedule');
            if(!box)return;
            _schedPicked=picked;
            const start=startTuesdayFor(picked);
            const dates=[];for(let i=0;i<7;i++){dates.push(new Date(start.getFullYear(),start.getMonth(),start.getDate()+i));}
            const md=d=>(d.getMonth()+1)+'月'+d.getDate()+'日';
            const esc=v=>String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/"/g,'&quot;');
            const checks=schedChecks;
            const cellHtml=(items,iso,name)=>items.map(t=>{
                const k=name+'|'+iso+'|'+t;const v=checks[k];
                return '<label class="sched-chk'+(v?' chk-done':'')+'" title="'+esc(checkMeta(v))+'"><input type="checkbox" data-k="'+esc(k)+'"'+(v?' checked':'')+'>'+esc(t)+'</label>';
            }).join('');
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
                        const items=schedCell(r,dates[i],i);
                        const inner=items.length?cellHtml(items,fmtYMDDash(dates[i]),r.name):'';
                        html+='<td>'+(r.shift==='日'?inner:'')+'</td><td>'+(r.shift==='夜'?inner:'')+'</td>';
                    }
                    html+='</tr>';
                });
                html+='</tbody></table></div>';
            });
            box.innerHTML=html;
            if(!box.dataset.bound){
                box.dataset.bound='1';
                box.addEventListener('change',e=>{
                    const cb=e.target;
                    if(!cb||!cb.matches||!cb.matches('input[type=checkbox][data-k]'))return;
                    const k=cb.getAttribute('data-k');
                    if(cb.checked)schedChecks[k]=1; else delete schedChecks[k];
                    saveSchedCheck(k,cb.checked);
                });
            }
        }

        // down chart 作業區上方：各 entity 的 ADDER Target vs 本週 alarm 數
        function fmtMD(d){return String(d.getMonth()+1).padStart(2,'0')+'/'+String(d.getDate()).padStart(2,'0');}

        // 供 AI 聊天讀取：本週週報 + 作業區排程(含勾選人/時間) 的文字摘要
        function buildPageContext(){
            try{
                const picked=_schedPicked||new Date();
                const start=startTuesdayFor(picked);
                const end=new Date(start.getFullYear(),start.getMonth(),start.getDate()+6);
                const dates=[];for(let i=0;i<7;i++)dates.push(new Date(start.getFullYear(),start.getMonth(),start.getDate()+i));
                const wlabel='W'+getWeekNumber(start)+'（'+fmtMD(start)+'~'+fmtMD(end)+'）';
                let out='【目前頁面即時資料｜本週 '+wlabel+'；一週為週二~週一】\n';
                if(_lastStats){
                    out+='\n== NPW Alarm 週報（本週）==\n';
                    [['ADDER',true],['NON-ADDER',false]].forEach(function(p){
                        const blk=p[0],isA=p[1];
                        out+='['+blk+']\n';
                        ['NISACVD','SACVD'].forEach(function(ent){
                            const es=_lastStats[ent];
                            const ac=es?(isA?es.sum.alarmAdder:es.sum.alarmNonAdder):0;
                            const mon=es?(isA?es.sum.totalMonAdder:es.sum.totalMonNonAdder):0;
                            const rate=mon?((ac/mon*100).toFixed(2)+'%'):'0%';
                            out+='  '+ent+': Alarm '+ac+' / Monitor '+mon+'（rate '+rate+'），Weekly Target '+getWeeklyTargetCount(ent,isA)+'\n';
                            const key=fmtYMDDash(start)+'|'+ent+'|'+(isA?'ADDER':'NON_ADDER');
                            const cm=chartAlarmStats[key]||{},dm=chartAlarmDateStats[key]||{};
                            Object.keys(cm).forEach(function(ck){const a=ck.split('||');const ds=dm[ck]?Array.from(dm[ck]).sort().join(','):'';out+='    - '+a[1]+'（ID '+a[0]+'）次數'+cm[ck]+' 日期'+ds+'\n';});
                        });
                    });
                }
                out+='\n== 測機排程（作業區，本週）✓=已完成 ==\n';
                SCHEDULE.forEach(function(g){
                    out+='# '+g.title+'\n';
                    g.rows.forEach(function(r){
                        for(let i=0;i<7;i++){
                            const items=schedCell(r,dates[i],i);
                            if(!items.length)continue;
                            const iso=fmtYMDDash(dates[i]);
                            const parts=items.map(function(t){const v=schedChecks[r.name+'|'+iso+'|'+t];return t+(v?('[✓'+((v&&v.by)?v.by:'')+((v&&v.at)?(' '+v.at):'')+']'):'');});
                            out+='  '+r.name+'('+r.shift+') '+fmtMD(dates[i])+'：'+parts.join('、')+'\n';
                        }
                    });
                });
                return out;
            }catch(e){return '';}
        }
        window.__npwPageContext=buildPageContext;

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
                    const portSet=chartPort[mkey];
                    const ports=portSet?Array.from(portSet).sort().join(', '):'';
                    const seqSet=chartAlarmSeq[mkey];
                    const chartSeq=(seqSet&&seqSet.size)?Array.from(seqSet)[0]:'';
                    const pointValue=chartAlarmMean[mkey];
                    const wafer=chartAlarmWafer[mkey];
                    const parameter=chartParameter[mkey];
                    const monTypes=chartMon[mkey]?Array.from(chartMon[mkey]).sort():[];
                    allRows.push({entity,chartId,chartName,cnt,nameKey,dates,ports,monTypes,mkey,measurePu,processUnit,chartSeq,pointValue,wafer,parameter});
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

            const colCount=isAdder?13:12;
            let head=`<tr><th colspan="${colCount}">${blockLabel} - Chart Alarm Detail (${fmtYMDDash(start)})</th></tr>
                <tr><th style="width:80px;">Entity</th><th style="width:110px;">Tool_name</th><th style="width:80px;">CHART_ID</th><th class="cn-col">CHART_NAME</th>
                <th style="width:90px;text-align:center;">Monitor type</th><th style="width:70px;text-align:center;">Alarm 次數</th><th style="width:160px;">ALARM 日期</th><th style="width:90px;">Port</th>`;
            if(isAdder)head+=`<th style="width:380px;text-align:center;">Trend_Chart</th><th style="width:200px;text-align:center;">PRE_Map</th><th style="width:200px;text-align:center;">ADDER_Map</th><th style="width:110px;">Measure_Tool</th><th style="width:70px;text-align:center;">EMST 填寫</th>`;
            else head+=`<th style="width:380px;text-align:center;">Trend_Chart</th><th style="width:200px;text-align:center;">Profile</th><th style="width:110px;">Measure_Tool</th><th style="width:70px;text-align:center;">EMST 填寫</th>`;
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
                // 對角度用：帶 Tool_name / Port / CHART_NAME，供點 ADDER_map 開 Wafer Match Tool 推導參數
                const wmAttr=`data-wm-tool="${escapeHtml(r.processUnit||'')}" data-wm-port="${escapeHtml(r.ports||'')}" data-wm-cname="${escapeHtml(r.chartName||'')}"`;
                const puInit=escapeHtml(parseMeasurePu(r.measurePu));
                const previewCell=`<td class="npw-cell-preview"><div class="npw-spark" data-cid="${cid}" data-block="${isAdder?'A':'N'}"><canvas></canvas></div></td>`;
                const measureCell=`<td><span class="map-info" ${da}>${puInit||'<span style="color:#999;">...</span>'}</span></td>`;
                // EMST 填寫區：每筆 alarm 一顆按鈕，點擊以彈窗開 OCAP 明細頁（OCAP/OCAP.aspx 深連結）
                const emstCell=`<td style="text-align:center;"><button type="button" class="emst-btn" data-pk="${escapeHtml(r.mkey)}" onclick="emstOpen(this)">EMST</button></td>`;
                let extra='';
                if(isAdder){
                    extra=previewCell+
                          `<td class="npw-cell-map"><span class="pre-map" ${da} style="color:#999;">...</span></td>`+
                          `<td class="npw-cell-map"><span class="adder-map" ${da} ${wmAttr} style="color:#999;">...</span></td>`+
                          measureCell+emstCell;
                }else{
                    const waferAttr=`data-wafer="${escapeHtml(r.wafer==null?'':String(r.wafer))}"`;
                    const profileCell=`<td class="npw-cell-map"><span class="profile-img" data-site="${site}" data-cid="${cid}" data-seq="${seq}" data-pv="${pv}" ${waferAttr} ${wmAttr} style="color:#999;">...</span></td>`;
                    extra=previewCell+profileCell+measureCell+emstCell;
                }
                _emstRows[r.mkey]=Object.assign({isAdder},r);  // 供 EMST 明細彈窗取用該列資料
                // Monitor type：PM/NORMAL 藍色、DOWN（及其他）黑色
                const mtHtml=(r.monTypes||[]).map(t=>{
                    const up=String(t).toUpperCase();
                    const col=(up==='PM'||up==='NORMAL')?'#1976d2':'#111';
                    return `<span style="color:${col};font-weight:700;">${escapeHtml(t)}</span>`;
                }).join(', ');
                html+=`<tr class="${rowClass}"><td>${escapeHtml(r.entity)}</td><td>${escapeHtml(r.processUnit||'')}</td><td>${cid}</td><td class="cn-col">${nameHtml}</td>
                    <td style="text-align:center;">${mtHtml}</td>
                    <td style="text-align:center;">${escapeHtml(r.cnt)}</td><td>${escapeHtml(datesText)}</td><td class="port-cell" data-pk="${escapeHtml(r.mkey)}">${escapeHtml(r.ports||(_portsLoading?'...':''))}</td>${extra}</tr>`;
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
        const YBOUND_PCT = 0.10;      // ADDER：上限 UCL×(1+10%)（下限固定 0）
        const YBOUND_PCT_NON = 0.01;  // NON-ADDER：上限 UCL×(1+1%)、下限 LCL×(1-1%)

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
                // ADDER：Y 軸最小值固定 0；NON-ADDER 維持 LCL×(1-pct)
                yMin=(opts.block==='A')?0:((l!=null)?l*(1-opts.uclLclPct):0);
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
                const opts={block:block==='A'?'A':'N',uclLclPct:block==='A'?YBOUND_PCT:YBOUND_PCT_NON};
                drawSpark(el.querySelector('canvas'),series[cid]||[],days,cid,opts);
            });
        }

        // 共用：以併發方式對一組節點查 MAP 代理，再交給 apply 回填
        // extraQuery：額外附加在 URL 後（如 profile 的 &keyword=RAW）
        function mapThumbHtml(imgUrl,alt){
            return `<a href="openie:${encodeURIComponent(imgUrl)}" target="_blank" rel="noopener noreferrer" title="Open ${alt} (IE)">`
                + `<img class="adder-map-thumb" src="${escapeHtml(imgUrl)}" alt="${alt}" loading="lazy" /></a>`;
        }
        // NON-ADDER Profile 縮圖：點擊開啟 Wafer Match Tool（對角度）。
        // side/chamber/offset 由 CHART_NAME 推導（wmOpenFromProfile）。
        function profileThumbHtml(imgUrl,tool,port,cname){
            return `<a href="javascript:void(0)" title="點擊對角度（Wafer Match）" `
                + `onclick="wmOpenFromProfile(this)" data-img="${escapeHtml(imgUrl)}" `
                + `data-tool="${escapeHtml(tool||'')}" data-port="${escapeHtml(port||'')}" data-cname="${escapeHtml(cname||'')}">`
                + `<img class="adder-map-thumb" src="${escapeHtml(imgUrl)}" alt="Profile RAW" loading="lazy" /></a>`;
        }
        // ADDER MAP 縮圖：點擊開啟 Wafer Match Tool（對角度），把此 map 當 wafer 貼上並轉到對好的角度。
        // tool/port/cname 來自該列 data-wm-*，用來推導 mode/CASS/side/station。
        function adderMapThumbHtml(imgUrl,tool,port,cname){
            return `<a href="javascript:void(0)" title="點擊對角度（Wafer Match）" `
                + `onclick="wmOpenFromMap(this)" data-img="${escapeHtml(imgUrl)}" `
                + `data-tool="${escapeHtml(tool||'')}" data-port="${escapeHtml(port||'')}" data-cname="${escapeHtml(cname||'')}">`
                + `<img class="adder-map-thumb" src="${escapeHtml(imgUrl)}" alt="ADDER MAP" loading="lazy" /></a>`;
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
                el.innerHTML=(d&&d.adderMapImgUrl)?adderMapThumbHtml(String(d.adderMapImgUrl),el.getAttribute('data-wm-tool'),el.getAttribute('data-wm-port'),el.getAttribute('data-wm-cname')):'-';
            }
        }
        async function hydrateOne(el){
            if(el.dataset.hydrated)return; el.dataset.hydrated='1';
            const site=el.getAttribute('data-site')||'12AP58';
            if(el.classList.contains('profile-img')){
                const cid=el.getAttribute('data-cid')||'',seq=el.getAttribute('data-seq')||'',pv=el.getAttribute('data-pv')||'',wafer=el.getAttribute('data-wafer')||'';
                if(!cid||!seq){el.textContent='-';return;}
                const d=await fetchProfile(site,cid,seq,pv,wafer);
                if(d&&d.ok&&d.imgUrl)el.innerHTML=profileThumbHtml(String(d.imgUrl),el.getAttribute('data-wm-tool'),el.getAttribute('data-wm-port'),el.getAttribute('data-wm-cname')); else el.textContent='-';
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

        // ===== EMST 填寫明細彈窗（參考 OCAP.aspx 明細頁，本頁自帶；資料走本頁 op）=====
        const _emstRows={};            // mkey -> 該列資料（建表時登錄）
        let _emstSeq=0, _emstCur=null, _emstBound=false;
        let _emst={saved:false,touched:{}};   // saved=已有儲存內容（預填不覆蓋）；touched=使用者已動過的欄位
        const $e=id=>document.getElementById(id);
        function emSetText(id,v){const el=$e(id);const t=(v==null||String(v).trim()==='')?'':String(v);el.textContent=t||'—';el.classList.remove('pending');}
        function emStatus(text,kind){const el=$e('emst-status');el.textContent=text||'';el.className='status'+(kind?' '+kind:'');}
        // EMST 的 Tool：ADDER 用 Tool_name；NON-ADDER 用 Tool_name + RECIPE 最後一段尾碼（限 1~3 英文字母，Tool_name 已含 chamber 時不加）
        function emstToolName(tool,recipe,isAdder){
            tool=String(tool||'').trim().toUpperCase();
            if(isAdder||!tool)return tool;
            if(/^[A-Z0-9]+-[A-Z]\d{1,2}[A-Z]+$/.test(tool))return tool;
            const r=String(recipe||'').trim();const i=r.lastIndexOf('-');if(i<0)return tool;
            const suf=r.substring(i+1).trim().toUpperCase();
            return /^[A-Z]{1,3}$/.test(suf)?tool+suf:tool;
        }
        function emFmtNum(v){if(v==null||v==='')return '';const n=Number(String(v).replace(/,/g,''));return isFinite(n)?n.toLocaleString():String(v);}
        function emWaferCountSummary(rows){if(!rows||!rows.length)return '';if(rows.length===1)return emFmtNum(rows[0].DATA_VAL);return rows.map(r=>r.DISP_EQPID+': '+emFmtNum(r.DATA_VAL)).join('; ');}
        // 一行一個計數器：EQPID · METERTYPE 現值 / SPEC；經過的 chamber 標藍、達 SPEC 標紅
        function emRenderWaferCount(data){
            const hit={};(data.chambers||[]).forEach(c=>hit[c]=true);
            return data.rows.map(r=>{
                const val=Number(String(r.DATA_VAL==null?'':r.DATA_VAL).replace(/,/g,''));
                const spec=Number(String(r.SPEC_VAL==null?'':r.SPEC_VAL).replace(/,/g,''));
                const over=isFinite(val)&&isFinite(spec)&&r.SPEC_VAL!=null&&r.SPEC_VAL!==''&&val>=spec;
                const cls='wc-line'+(hit[r.EQPID]?' hit':'')+(over?' over':'');
                return `<div class="${cls}"><span class="wc-eq">${escapeHtml(r.DISP_EQPID)}</span><span class="wc-meter">${escapeHtml(r.DISP_METERTYPE)}</span><span class="wc-val">${escapeHtml(emFmtNum(r.DATA_VAL))}</span><span class="wc-spec">/ ${(r.SPEC_VAL==null||r.SPEC_VAL==='')?'—':escapeHtml(emFmtNum(r.SPEC_VAL))}</span></div>`;
            }).join('');
        }
        function emLoadWaferCount(seq,tool,recipe){
            if(!tool){emSetText('em-wafercount','');return;}
            const scope=/XFER/i.test(String(recipe||''))?'MF':'CHAMBER';
            fetch(PAGE+'?'+new URLSearchParams({op:'wafercount',tool,scope}).toString(),{cache:'no-store'})
                .then(res=>res.json()).then(data=>{
                    if(seq!==_emstSeq)return;
                    const el=$e('em-wafercount');el.classList.remove('pending');
                    if(!data.ok)throw new Error(data.error||'HTTP 錯誤');
                    const finalScope=data.scope||scope;
                    const scopeText=finalScope==='MF'?(data.noSuffixAsMf?'MF，Tool_name 沒有 chamber 字母':'MF，RECIPE 含 XFER'):'chamber';
                    if(!data.rows||!data.rows.length){el.textContent='—（查無計數器資料，範圍：'+scopeText+'，查的是 '+(data.mom||tool)+'）';return;}
                    const notes=[];if(data.noSuffixAsMf)notes.push('Tool_name 沒有 chamber 字母，視為 MF');
                    el.innerHTML=emRenderWaferCount(data)+(notes.length?'<div class="wc-note">'+escapeHtml(notes.join('；'))+'</div>':'');
                    if(!_emst.saved&&!_emst.touched.wc)$e('emst-wc').value=emWaferCountSummary(data.rows);
                }).catch(err=>{if(seq!==_emstSeq)return;const el=$e('em-wafercount');el.classList.remove('pending');el.textContent='載入失敗：'+err.message;});
        }
        // 讀已儲存的 EMST 內容；有的話四個欄位都用儲存值
        function emLoadSaved(seq){
            const c=_emstCur;if(!c)return;
            fetch(PAGE+'?op=emst&uchart_id='+encodeURIComponent(c.cid)+'&chart_seq='+encodeURIComponent(c.cseq)+'&_='+Date.now(),{cache:'no-store'})
                .then(res=>res.json()).then(data=>{
                    if(seq!==_emstSeq)return;
                    if(!data||!data.ok)throw new Error((data&&data.error)||'HTTP 錯誤');
                    if(!data.exists||!data.note){emStatus('尚未儲存');return;}
                    const n=data.note;_emst.saved=true;
                    $e('emst-tool').value=n.tool||'';$e('emst-wc').value=n.waferCount||'';
                    $e('emst-action').value=n.action||'';$e('emst-followup').value=n.followUp||'';
                    emStatus('上次儲存：'+(n.updatedAt||''),'ok');
                }).catch(err=>{if(seq!==_emstSeq)return;emStatus('讀取儲存內容失敗：'+err.message,'error');});
        }
        function emSave(){
            const c=_emstCur;if(!c)return;const seq=_emstSeq;
            const payload={chart_name:c.r.chartName||'',block:c.isAdder?'ADDER':'NON-ADDER',
                tool:$e('emst-tool').value.trim(),waferCount:$e('emst-wc').value.trim(),
                action:$e('emst-action').value.trim(),followUp:$e('emst-followup').value.trim()};
            $e('emst-save').disabled=true;emStatus('儲存中…');
            fetch(PAGE+'?op=emst&uchart_id='+encodeURIComponent(c.cid)+'&chart_seq='+encodeURIComponent(c.cseq),
                  {method:'POST',headers:{'Content-Type':'application/json; charset=utf-8'},body:JSON.stringify(payload)})
                .then(res=>res.json().then(d=>{if(!res.ok||!d.ok)throw new Error(d.error||('HTTP '+res.status));return d;}))
                .then(d=>{if(seq!==_emstSeq)return;_emst.saved=true;emStatus('已儲存：'+((d.note&&d.note.updatedAt)||''),'ok');})
                .catch(err=>{if(seq!==_emstSeq)return;emStatus('儲存失敗：'+err.message,'error');})
                .then(()=>{if(seq===_emstSeq)$e('emst-save').disabled=false;});
        }
        function emTemplate(){
            return '1.Tool: '+$e('emst-tool').value.trim()+'\n2.Wafer count: '+$e('emst-wc').value.trim()
                +'\n3.Action: '+$e('emst-action').value.trim()+'\n4.Follow up: '+$e('emst-followup').value.trim();
        }
        function emCopy(){
            const text=emTemplate();
            const done=()=>emStatus('已複製公版文字','ok'),fail=()=>emStatus('複製失敗，請手動選取','error');
            const legacy=()=>{try{const ta=document.createElement('textarea');ta.value=text;ta.style.position='fixed';ta.style.opacity='0';document.body.appendChild(ta);ta.select();const ok=document.execCommand('copy');document.body.removeChild(ta);return ok;}catch(e){return false;}};
            if(navigator.clipboard&&navigator.clipboard.writeText)navigator.clipboard.writeText(text).then(done,()=>legacy()?done():fail());
            else legacy()?done():fail();
        }
        function emClose(){$e('emstModal').style.display='none';document.body.style.overflow='';_emstSeq++;}
        function emBindOnce(){
            if(_emstBound)return;_emstBound=true;
            $e('emst-save').addEventListener('click',emSave);
            $e('emst-copy').addEventListener('click',emCopy);
            $e('emst-tool').addEventListener('input',()=>{_emst.touched.tool=true;});
            $e('emst-wc').addEventListener('input',()=>{_emst.touched.wc=true;});
            $e('em-close').addEventListener('click',emClose);
            $e('emstModal').addEventListener('click',function(e){if(e.target===this)emClose();});
        }
        function emstOpenRow(r){
            emBindOnce();
            const seq=++_emstSeq;const isAdder=!!r.isAdder;
            const cid=String(r.chartId||'').replace(/\D/g,''),cseq=String(r.chartSeq||'').replace(/\D/g,'');
            _emstCur={r,seq,isAdder,cid,cseq,tool:'',recipe:''};
            _emst={saved:false,touched:{}};
            // 標題與表格已知欄位
            $e('em-block').textContent=isAdder?'ADDER':'NON-ADDER';$e('em-block').className='block'+(isAdder?'':' non-adder');
            $e('em-title').textContent=r.chartName||'(無 CHART_NAME)';
            $e('em-subtitle').textContent=(r.processUnit||'')+' · '+((r.dates&&r.dates.length)?r.dates.join(', '):'');
            emSetText('em-tool',r.processUnit);emSetText('em-ids',cid+' / '+cseq);emSetText('em-port',r.ports);
            emSetText('em-measure',parseMeasurePu(r.measurePu));emSetText('em-wafer',r.wafer);emSetText('em-mean',r.pointValue);emSetText('em-parameter',r.parameter);
            ['em-lot','em-recipe','em-status-v','em-create','em-owner','em-wafercount'].forEach(id=>{$e(id).textContent='載入中…';$e(id).classList.add('pending');});
            $e('em-card-premap').hidden=!isAdder;$e('em-card-addermap').hidden=!isAdder;$e('em-card-profile').hidden=isAdder;
            $e('em-grid').className='detail-grid'+(isAdder?'':' non-adder');
            $e('em-premap').textContent='載入中…';$e('em-addermap').textContent='載入中…';$e('em-profile').textContent='載入中…';
            $e('em-trend-status').textContent='載入中…';$e('em-trend-range').textContent='';
            // EMST 表單重設
            $e('emst-tool').value=String(r.processUnit||'').toUpperCase();$e('emst-wc').value='';$e('emst-action').value='';$e('emst-followup').value='';
            $e('emst-meta').textContent=isAdder?'ADDER：Tool 取 Tool_name':'NON-ADDER：Tool 取 Tool_name + RECIPE 尾碼';
            emStatus('');$e('emst-save').disabled=false;
            $e('emstModal').style.display='flex';document.body.style.overflow='hidden';
            if(!cid||!cseq){
                ['em-lot','em-recipe','em-status-v','em-create','em-owner'].forEach(id=>emSetText(id,''));
                $e('em-wafercount').textContent='—';$e('em-trend-status').textContent='此筆缺少 CHART_ID / CHART_SEQ';
                emStatus('此筆缺少 CHART_ID / CHART_SEQ，無法儲存','error');$e('emst-save').disabled=true;
                return;
            }
            // 1) 明細：OCAP 紀錄 + chart 列（無 OCAP 紀錄時仍回 chart 列）
            fetch(PAGE+'?op=ocapdetail&uchart_id='+encodeURIComponent(cid)+'&chart_seq='+encodeURIComponent(cseq)+'&_='+Date.now(),{cache:'no-store'})
                .then(res=>res.json()).then(data=>{
                    if(seq!==_emstSeq)return;
                    if(!data.ok)throw new Error(data.error||'HTTP 錯誤');
                    const d=data.row||{};
                    emSetText('em-lot',d.LOT);emSetText('em-recipe',d.RECIPE);
                    emSetText('em-status-v',data.ocapFound?d.STATUS:'（無 OCAP 紀錄）');
                    emSetText('em-create',d.CREATE_TIME||d.NPW_UPDATE_TIME);emSetText('em-owner',d.CHART_OWNER);
                    if(d.WAFER!=null&&String(d.WAFER)!=='')emSetText('em-wafer',d.WAFER);
                    if(d.MEAN_VALUE!=null&&String(d.MEAN_VALUE)!=='')emSetText('em-mean',d.MEAN_VALUE);
                    const baseTool=d.PROCESSUNIT||d.PROCESSINGUNIT||r.processUnit||'';const recipe=d.RECIPE||'';
                    _emstCur.tool=emstToolName(baseTool,recipe,isAdder);_emstCur.recipe=recipe;
                    const tEl=$e('em-tool');tEl.textContent=baseTool||'—';
                    if(_emstCur.tool&&_emstCur.tool!==String(baseTool).toUpperCase())tEl.textContent+='（EMST / wafer count 用 '+_emstCur.tool+'）';
                    if(!_emst.saved&&!_emst.touched.tool)$e('emst-tool').value=_emstCur.tool;
                    const meas=d.MEAS_EQUIPMENT||parseMeasurePu(d.MEASUREPU);if(meas)emSetText('em-measure',meas);
                    emLoadWaferCount(seq,_emstCur.tool,recipe);
                    emLoadSaved(seq);
                }).catch(err=>{
                    if(seq!==_emstSeq)return;
                    ['em-lot','em-recipe','em-status-v','em-create','em-owner'].forEach(id=>emSetText(id,''));
                    const el=$e('em-wafercount');el.classList.remove('pending');el.textContent='明細載入失敗：'+err.message;
                    _emstCur.tool=emstToolName(r.processUnit,'',isAdder);
                    if(!_emst.touched.tool)$e('emst-tool').value=_emstCur.tool;
                    emLoadSaved(seq);
                });
            // 2) Map / Profile：沿用本頁 proxy 與縮圖（可點擊對角度）
            const puUp=String(r.processUnit||'').trim().toUpperCase();const site=puUp.startsWith('OXSE-A')?'12AP14':'12AP58';
            const pv=r.pointValue==null?'':String(r.pointValue);
            if(isAdder){
                fetchProxy(site,cid,cseq,pv).then(d=>{
                    if(seq!==_emstSeq)return;
                    if(!d||!d.ok){$e('em-premap').textContent='—';$e('em-addermap').textContent='—';return;}
                    $e('em-premap').innerHTML=d.preMapImgUrl?mapThumbHtml(String(d.preMapImgUrl),'PRE MAP'):'—';
                    $e('em-addermap').innerHTML=d.adderMapImgUrl?adderMapThumbHtml(String(d.adderMapImgUrl),r.processUnit,r.ports,r.chartName):'—';
                    if(d.measurePU&&$e('em-measure').textContent==='—')emSetText('em-measure',parseMeasurePu(d.measurePU));
                });
            }else{
                fetchProfile(site,cid,cseq,pv,r.wafer==null?'':String(r.wafer)).then(d=>{
                    if(seq!==_emstSeq)return;
                    $e('em-profile').innerHTML=(d&&d.ok&&d.imgUrl)?profileThumbHtml(String(d.imgUrl),r.processUnit,r.ports,r.chartName):'無 Profile 圖';
                });
            }
            // 3) Trend：沿用 op=chartdata + drawSpark（近 60 天，alarm 日標紅）
            const endDate=(r.dates&&r.dates.length)?r.dates[r.dates.length-1]:toISODateLocal(new Date());
            fetch(PAGE+'?'+new URLSearchParams({op:'chartdata',cids:cid,end:endDate,days:'60'}).toString(),{cache:'no-store'})
                .then(res=>res.json()).then(data=>{
                    if(seq!==_emstSeq)return;
                    const pts=(data.series&&data.series[cid])||[];
                    $e('em-trend-range').textContent=pts.length?('（'+pts.length+' 點）'):'';
                    if(!pts.length){$e('em-trend-status').textContent='此區間沒有趨勢資料';return;}
                    $e('em-trend-status').textContent='';
                    const cv=$e('em-spark');
                    if(window.Chart&&Chart.getChart){const old=Chart.getChart(cv);if(old)old.destroy();}
                    drawSpark(cv,pts,r.dates||[],cid,{block:isAdder?'A':'N',uclLclPct:isAdder?YBOUND_PCT:YBOUND_PCT_NON});
                }).catch(err=>{if(seq!==_emstSeq)return;$e('em-trend-status').textContent='Trend chart 載入失敗：'+err.message;});
        }
        // 表格 EMST 按鈕（inline onclick）用的全域入口
        window.emstOpen=function(btn){
            const r=_emstRows[btn.getAttribute('data-pk')||''];
            if(!r){alert('找不到此列資料，請重新整理');return;}
            // Port 為背景載入，可能晚於建表：以該列 Port 欄當下的值為準
            try{const pc=btn.closest('tr').querySelector('td.port-cell');const t=pc?pc.textContent.trim():'';if(t&&t!=='...')r.ports=t;}catch(e){}
            emstOpenRow(r);
        };
        window.emstClose=emClose;

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
            function updateWeekHint(d){const wd=['日','一','二','三','四','五','六'][d.getDay()];weekHint.textContent='（'+wd+'）';}

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
                _portsLoading=true;  // 主表渲染時 Port 欄先顯示 ...（查詢在渲染後才發出）
                try{await loadFromDb(picked);refreshTables(picked);}catch(e){/* 已顯示 */}
                // Port 跨庫查詢等主表渲染完才啟動：即使伺服器將同一使用者的
                // 請求序列化（ASP.NET session 鎖），主載入也不會排在慢查詢後面
                loadPorts(picked);
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

            // 切到作業區時重抓共用勾選狀態（看別人最新的勾選）
            const dcTab=document.querySelector('.seg-btn[data-sec="downchart"]');
            if(dcTab)dcTab.addEventListener('click',()=>loadSchedChecksServer());

            reload(today);
            loadSchedChecksServer(); // 載入共用勾選狀態，完成後會重繪排程
            // 多人即時同步：作業區開著時每 12 秒重抓一次別人的勾選
            setInterval(()=>{
                const sec=document.getElementById('sec-downchart');
                if(sec&&!sec.hidden)loadSchedChecksServer();
            },12000);
        })();
    })();
    </script>

    <!-- ============================================================
         對角度（Wafer Match）：點 ADDER_map 時彈窗，iframe 載入 WaferMatch.html
         並以推導出的 mode/CASS/side/station + 該 map 圖自動帶入。
         ============================================================ -->
    <!-- ============================================================
         EMST 填寫明細彈窗：點表格每筆 alarm 的 EMST 按鈕開啟。
         版面參考 OCAP.aspx 點 CHART_NAME 的明細頁，但資料全走本頁 op（ocapdetail /
         wafercount / emst），Map、Profile、Trend 沿用本頁既有 proxy，不連結 OCAP.aspx。
         ============================================================ -->
    <div id="emstModal">
      <div class="em-modal" role="dialog" aria-modal="true" aria-labelledby="em-title">
        <div class="em-head">
          <div>
            <h3><span class="block" id="em-block">ADDER</span><span id="em-title">—</span></h3>
            <div class="sub" id="em-subtitle"></div>
          </div>
          <button type="button" class="em-close" id="em-close" title="關閉" aria-label="關閉">&times;</button>
        </div>
        <div class="em-body">
          <div class="info-grid">
            <div><div class="k">Tool_name</div><div class="v" id="em-tool">—</div></div>
            <div><div class="k">Port</div><div class="v" id="em-port">—</div></div>
            <div><div class="k">Measure_Tool</div><div class="v" id="em-measure">—</div></div>
            <div><div class="k">CHART_ID / SEQ</div><div class="v" id="em-ids">—</div></div>
            <div><div class="k">LOT</div><div class="v pending" id="em-lot">載入中…</div></div>
            <div><div class="k">WAFER</div><div class="v" id="em-wafer">—</div></div>
            <div><div class="k">RECIPE</div><div class="v pending" id="em-recipe">載入中…</div></div>
            <div><div class="k">PARAMETER</div><div class="v" id="em-parameter">—</div></div>
            <div><div class="k">STATUS（OCAP）</div><div class="v pending" id="em-status-v">載入中…</div></div>
            <div><div class="k">CREATE_TIME</div><div class="v pending" id="em-create">載入中…</div></div>
            <div><div class="k">MEAN_VALUE</div><div class="v" id="em-mean">—</div></div>
            <div><div class="k">CHART_OWNER</div><div class="v pending" id="em-owner">載入中…</div></div>
            <div class="wide"><div class="k">Wafer count（PM 後累計 / SPEC；RECIPE 含 XFER 或 Tool_name 無 chamber 尾碼看 MF，否則看 chamber）</div><div class="v pending" id="em-wafercount">載入中…</div></div>
          </div>
          <div class="detail-grid" id="em-grid">
            <div class="em-card">
              <h4>Trend_Chart <small id="em-trend-range"></small></h4>
              <div class="spark"><canvas id="em-spark"></canvas></div>
              <div class="map-hint" id="em-trend-status"></div>
            </div>
            <div class="em-card" id="em-card-premap"><h4>PRE_Map</h4><div class="map-box" id="em-premap">載入中…</div></div>
            <div class="em-card" id="em-card-addermap"><h4>ADDER_Map <small>點擊可對角度</small></h4><div class="map-box" id="em-addermap">載入中…</div></div>
            <div class="em-card" id="em-card-profile" hidden><h4>Profile <small>點擊可對角度</small></h4><div class="map-box" id="em-profile">載入中…</div></div>
          </div>
          <div class="em-card emst">
            <h4>EMST 填寫 <small id="emst-meta"></small></h4>
            <div class="emst-grid">
              <label>1. Tool<input type="text" id="emst-tool" autocomplete="off"></label>
              <label>2. Wafer count<input type="text" id="emst-wc" autocomplete="off"></label>
              <label class="full">3. Action<textarea id="emst-action" rows="3" placeholder="使用者填寫"></textarea></label>
              <label class="full">4. Follow up<textarea id="emst-followup" rows="3" placeholder="使用者填寫"></textarea></label>
            </div>
            <div class="emst-actions">
              <button type="button" id="emst-save">儲存</button>
              <button type="button" class="ghost" id="emst-copy">複製公版文字</button>
              <span class="status" id="emst-status"></span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div id="wmatchModal" style="display:none;position:fixed;z-index:1200;left:0;top:0;width:100%;height:100%;background:rgba(0,0,0,0.6);">
        <div style="position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:96vw;height:92vh;background:#fff;border-radius:10px;box-shadow:0 20px 60px rgba(0,0,0,0.4);overflow:hidden;">
            <div style="display:flex;align-items:center;justify-content:space-between;padding:8px 14px;background:#1976d2;color:#fff;">
                <span id="wmatchTitle" style="font-weight:700;font-size:14px;">對角度 · Wafer Match</span>
                <span onclick="wmClose()" style="cursor:pointer;font-size:24px;line-height:1;">&times;</span>
            </div>
            <iframe id="wmatchFrame" title="Wafer Match Tool" style="border:0;width:100%;height:calc(100% - 40px);" src="about:blank"></iframe>
        </div>
    </div>
    <script>
        // 由 ADDER_map 縮圖 onclick 呼叫（全域）。從 data-* 推導對角度參數並開啟 iframe。
        function wmMode(entity, bnum){
            entity=String(entity||'').toUpperCase();
            const n=parseInt(bnum,10);
            if(entity==='NISACVD'){
                if((n>=1&&n<=5)||(n>=9&&n<=14))return 'FI5.X';
                if(n>=6&&n<=8)return 'FI6.4';
            }else if(entity==='SACVD'){
                if((n>=1&&n<=5)||n===7)return 'FI5.X';
                if(n===6||(n>=8&&n<=12)||n===81)return 'FI6.4';
            }
            return 'FI5.X';  // 未列入者的預設
        }
        function wmDeriveParams(tool, portStr, cname){
            const m=String(tool||'').toUpperCase().match(/(NISACVD|SACVD)-B(\d+)\s*([A-Z]*)/);
            if(!m)return null;
            const entity=m[1], bnum=m[2], letter=m[3]||'';
            const mode=wmMode(entity,bnum);
            const firstPort=(String(portStr||'').split(',')[0]||'').trim();
            const pnum=parseInt(firstPort,10);
            const cass=(pnum>=1&&pnum<=4)?String.fromCharCode(64+pnum):'A';  // 1->A..4->D
            const side=/W2/i.test(String(cname||''))?'S2':'S1';              // W1->S1, W2->S2
            // 尾碼可含多個 chamber 字母（如 CB = CHC+CHB、CA = CHC+CHA），
            // 每個字母都要對位置；無字母(XFER NG) -> LL
            const stMap={A:'CHA',B:'CHB',C:'CHC'};
            const parts=[];
            for(const ch of letter){ if(stMap[ch]) parts.push(stMap[ch]); }
            const station=parts.length?parts.join('+'):'LL';
            return {mode, cass, side, station, entity, bnum, letter};
        }
        function wmOpenFromMap(a){
            const img=a.getAttribute('data-img')||'';
            // Port 為背景載入，可能晚於 map 縮圖出現：以點擊當下該列 Port 欄的值為準
            let port=a.getAttribute('data-port')||'';
            try{
                const tr=a.closest('tr');
                const pc=tr&&tr.querySelector('td.port-cell');
                const t=pc?pc.textContent.trim():'';
                if(t&&t!=='...')port=t;
            }catch(e){}
            const p=wmDeriveParams(a.getAttribute('data-tool'), port, a.getAttribute('data-cname'));
            if(!p){ alert('無法從 Tool_name / Port / CHART_NAME 推導對角度參數'); return; }
            const qs='mode='+encodeURIComponent(p.mode)+'&cass='+encodeURIComponent(p.cass)
                    +'&side='+encodeURIComponent(p.side)+'&station='+encodeURIComponent(p.station)
                    +'&offset=0&img='+encodeURIComponent(img);
            document.getElementById('wmatchTitle').textContent=
                `對角度 · ${p.entity}-B${p.bnum}${p.letter}｜${p.mode}｜CASS ${p.cass}｜${p.side}｜${p.station}`;
            document.getElementById('wmatchFrame').src='WaferMatch.html?'+qs;
            document.getElementById('wmatchModal').style.display='block';
        }
        // NON-ADDER Profile 對角度：side / chamber / offset 由 CHART_NAME 推導
        //   side/chamber：名稱中 dash 分隔、形如 AC2/BC2/B2 的段落 ——
        //     字母=chamber（可多個，A/B/C -> CHA/CHB/CHC），尾數 1/2 -> S1/S2
        //   offset：含 HTN430D4 -> 300；符合 HTN%D1（%萬用）-> 0；其他 -> 180
        //   mode/CASS 與 ADDER 相同（Tool_name 對照表 / Port 1~4 -> A~D）
        function wmDeriveProfileParams(tool, portStr, cname){
            const m=String(tool||'').toUpperCase().match(/(NISACVD|SACVD)-B(\d+)/);
            if(!m)return null;
            const entity=m[1], bnum=m[2];
            const mode=wmMode(entity,bnum);
            const firstPort=(String(portStr||'').split(',')[0]||'').trim();
            const pnum=parseInt(firstPort,10);
            const cass=(pnum>=1&&pnum<=4)?String.fromCharCode(64+pnum):'A';
            const name=String(cname||'').toUpperCase();
            let side='S1', station='LL';
            const seg=name.split('-').find(s=>/^[ABC]{1,3}[12]$/.test(s));
            if(seg){
                const letters=seg.slice(0,-1), digit=seg.slice(-1);
                side=(digit==='2')?'S2':'S1';
                const stMap={A:'CHA',B:'CHB',C:'CHC'};
                const parts=[];
                for(const ch of letters){ if(stMap[ch]) parts.push(stMap[ch]); }
                if(parts.length)station=parts.join('+');
            }
            let offset=180;
            if(name.indexOf('HTN430D4')>=0)offset=300;
            else if(/HTN[A-Z0-9_]*D1(?![0-9])/.test(name))offset=0;
            return {mode, cass, side, station, offset, entity, bnum};
        }
        function wmOpenFromProfile(a){
            const img=a.getAttribute('data-img')||'';
            // Port 為背景載入，可能晚於縮圖出現：以點擊當下該列 Port 欄的值為準
            let port=a.getAttribute('data-port')||'';
            try{
                const tr=a.closest('tr');
                const pc=tr&&tr.querySelector('td.port-cell');
                const t=pc?pc.textContent.trim():'';
                if(t&&t!=='...')port=t;
            }catch(e){}
            const p=wmDeriveProfileParams(a.getAttribute('data-tool'), port, a.getAttribute('data-cname'));
            if(!p){ alert('無法從 Tool_name / Port / CHART_NAME 推導對角度參數'); return; }
            const qs='mode='+encodeURIComponent(p.mode)+'&cass='+encodeURIComponent(p.cass)
                    +'&side='+encodeURIComponent(p.side)+'&station='+encodeURIComponent(p.station)
                    +'&offset='+encodeURIComponent(p.offset)+'&img='+encodeURIComponent(img);
            document.getElementById('wmatchTitle').textContent=
                `對角度 · ${p.entity}-B${p.bnum}｜${p.mode}｜CASS ${p.cass}｜${p.side}｜${p.station}｜offset ${p.offset}°`;
            document.getElementById('wmatchFrame').src='WaferMatch.html?'+qs;
            document.getElementById('wmatchModal').style.display='block';
        }
        function wmClose(){
            document.getElementById('wmatchModal').style.display='none';
            document.getElementById('wmatchFrame').src='about:blank';  // 停止 iframe、釋放
        }
        document.getElementById('wmatchModal').addEventListener('click', function(e){ if(e.target===this) wmClose(); });
        // Esc：先關對角度視窗，其次關 EMST 明細（emstClose 由主程式掛在 window 上）
        document.addEventListener('keydown', function(e){
            if(e.key!=='Escape')return;
            if(document.getElementById('wmatchModal').style.display==='block')wmClose();
            else if(window.emstClose)window.emstClose();
        });
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
                    let msgs = s.history;
                    try {
                        const ctx = (window.__npwPageContext && window.__npwPageContext()) || '';
                        if (ctx) msgs = [{ role: 'system', content: '以下是使用者目前畫面上的即時資料（NPW Alarm 週報與測機排程作業區）。回答相關問題時請以此為依據：\n' + ctx }].concat(s.history);
                    } catch (e) { }
                    const res = await fetch(PROXY_URL, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json; charset=utf-8' },
                        body: JSON.stringify({ messages: msgs })
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
