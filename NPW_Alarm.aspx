<%@ Page Language="C#" AutoEventWireup="true" Inherits="NPW_Alarm" CodeFile="NPW_Alarm.aspx.cs" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>首頁</title>
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
            background: var(--bg-gradient);
            color: var(--text);
            min-height: 100vh;
        }
        .topbar {
            display: flex; align-items: center;
            padding: 12px 22px;
            background: var(--panel);
            border-bottom: 1px solid var(--border);
            gap: 14px;
        }
        .topbar h1 { font-size: 16px; margin: 0; }
        .wrap { max-width: 1100px; margin: 0 auto; padding: 24px; }
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
        <h1>網頁公版 — 首頁(無登入)</h1>
    </div>

    <div class="wrap">
        <div class="card">
            <h2>歡迎</h2>
            <p>這是 <code>web-template-lite</code> 公版的首頁 — <strong>沒有登入機制</strong>,任何人開網址都看得到。</p>
            <p>右下角 <strong>AI</strong> 圓鈕點開就有 LLM 對話視窗,圖文輸入都支援。
                所有 chat 請求送到 <code>NPW_Alarm.aspx?op=chat</code>,後端代理到 LLM gateway(API key 藏在 server)。</p>
        </div>
        <div class="card">
            <h2>下一步</h2>
            <p>把 <code>NPW_Alarm.aspx</code> 改成你自己的功能畫面。要連 DB 的話,在 code-behind 直接呼叫:</p>
            <p><code>var rows = DbHelper.QueryRows("SELECT * FROM your_table WHERE x = @p0", value);</code></p>
            <p>要加新 .aspx 頁面就直接加,沒有 auth gate 需要繞過。</p>
        </div>

        <div class="card">
            <div style="display:flex; gap:10px; align-items:center; flex-wrap:wrap; margin-bottom:8px;">
                <h2 style="margin:0;">NPW Alarm 週報</h2>
                <span id="awWeek" style="color:#0f4aa8; font-weight:700;"></span>
                <label style="font-size:13px;color:#64748b;">週(任一天)
                    <input id="awDate" type="date" style="padding:5px 8px;border:1px solid #cbd5e1;border-radius:6px;" />
                </label>
                <button id="awLoad" type="button" style="padding:6px 14px;border:0;border-radius:6px;background:#1976d2;color:#fff;cursor:pointer;">讀取</button>
                <span id="awStatus" style="color:#64748b;font-size:12px;"></span>
            </div>
            <div id="awContent"></div>
        </div>
    </div>

    <script>
    // NPW Alarm 週報：呼叫 NPW_Alarm.aspx?op=alarm
    (function () {
        // 週目標率(%)：依截圖預設，可在此調整（Target 算法待確認）
        const TARGET_RATE = {
            'ADDER':     { 'NISACVD': 1.17, 'SACVD': 1.35 },
            'NON-ADDER': { 'NISACVD': 0.60, 'SACVD': 0.75 }
        };
        const BLOCKS = ['ADDER', 'NON-ADDER'];
        const ENTITIES = ['NISACVD', 'SACVD'];
        const $ = id => document.getElementById(id);
        const esc = v => v == null ? '' : String(v).replace(/&/g, '&amp;').replace(/</g, '&lt;');
        const th = t => '<th style="border:1px solid #e2e8f0;padding:5px 7px;background:#f5f7fb;white-space:nowrap;">' + esc(t) + '</th>';
        const td = (t, a) => '<td style="border:1px solid #eef2f7;padding:4px 7px;text-align:' + (a || 'center') + ';white-space:nowrap;">' + esc(t) + '</td>';

        function render(data) {
            const wk = data.week || {};
            $('awWeek').textContent = (wk.label || '') + '  ' + (wk.start || '') + ' ~ ' + (wk.end || '');
            const days = wk.days || [];
            const alarms = data.alarms || [];
            const monMap = {};
            (data.monitor || []).forEach(m => { monMap[m.Block + '|' + m.Entity] = Number(m.MonitorCount) || 0; });

            let html = '';
            BLOCKS.forEach(block => {
                const blockAlarms = alarms.filter(a => a.Block === block);

                // ---- 摘要表 ----
                html += '<h3 style="margin:14px 0 6px;background:#dbeafe;padding:6px 10px;border-radius:6px;">' + block + '</h3>';
                html += '<div style="overflow:auto;"><table style="border-collapse:collapse;width:100%;font-size:12px;margin-bottom:8px;">';
                html += '<thead><tr>' + th('Entity') + days.map(d => th(d)).join('') +
                        th('Alarm Counts') + th('Alarm rate') + th('Weekly Target Rate') + th('Weekly Target Count') + th('Total Monitor Count') + '</tr></thead><tbody>';
                let totAlarm = 0, totMon = 0;
                ENTITIES.forEach(ent => {
                    const rows = blockAlarms.filter(a => a.Entity === ent);
                    const perDay = {}; days.forEach(d => perDay[d] = 0);
                    rows.forEach(a => { if (perDay[a.D] != null) perDay[a.D]++; });
                    const alarmCount = rows.length;
                    const mon = monMap[block + '|' + ent] || 0;
                    const rate = mon ? (alarmCount / mon * 100) : 0;
                    const tRate = (TARGET_RATE[block] && TARGET_RATE[block][ent]) || 0;
                    const tCount = Math.round(mon * tRate / 100);
                    totAlarm += alarmCount; totMon += mon;
                    html += '<tr>' + td(ent, 'left') + days.map(d => td(perDay[d] || '')).join('') +
                            td(alarmCount) + td(rate.toFixed(2) + '%') + td(tRate.toFixed(2) + '%') + td(tCount) + td(mon) + '</tr>';
                });
                const totRate = totMon ? (totAlarm / totMon * 100) : 0;
                html += '<tr style="font-weight:700;background:#f1f5f9;">' + td('Total Alarm', 'left') +
                        days.map(() => td('')).join('') + td(totAlarm) + td(totRate.toFixed(2) + '%') + td('') + td('') + td(totMon) + '</tr>';
                html += '</tbody></table></div>';

                // ---- 明細表 ----
                const detail = {};
                blockAlarms.forEach(a => {
                    if (!detail[a.CHART_NAME]) detail[a.CHART_NAME] = { entity: a.Entity, chartId: a.CHART_ID, name: a.CHART_NAME, dates: [] };
                    if (detail[a.CHART_NAME].dates.indexOf(a.D) < 0) detail[a.CHART_NAME].dates.push(a.D);
                });
                const dlist = Object.keys(detail).map(k => detail[k])
                    .sort((x, y) => x.entity.localeCompare(y.entity) || x.name.localeCompare(y.name));
                html += '<div style="font-weight:700;color:#0f4aa8;margin:4px 0;">' + block + ' — Chart Alarm Detail (' + (wk.label || '') + ')</div>';
                html += '<div style="overflow:auto;max-height:360px;border:1px solid #e5e7eb;border-radius:8px;"><table style="border-collapse:collapse;width:100%;font-size:12px;">';
                html += '<thead><tr>' + th('Entity') + th('CHART_ID') + th('CHART_NAME') + th('Alarm 次數') + th('ALARM 日期') + th('重複') + '</tr></thead><tbody>';
                dlist.forEach(r => {
                    const cnt = r.dates.length;
                    html += '<tr>' + td(r.entity, 'left') + td(r.chartId) +
                            '<td style="border:1px solid #eef2f7;padding:4px 7px;text-align:left;white-space:nowrap;color:#1d4ed8;">' + esc(r.name) + '</td>' +
                            td(cnt) + td(r.dates.sort().join(', '), 'left') + td(cnt > 1 ? 'Y' : '') + '</tr>';
                });
                if (!dlist.length) html += '<tr><td colspan="6" style="padding:8px;color:#94a3b8;">本週無 alarm</td></tr>';
                html += '</tbody></table></div>';
            });
            $('awContent').innerHTML = html;
        }

        async function load() {
            const qs = new URLSearchParams({ op: 'alarm' });
            const date = $('awDate').value;
            if (date) qs.set('date', date);
            $('awStatus').textContent = '讀取中…';
            try {
                const res = await fetch('NPW_Alarm.aspx?' + qs.toString(), { cache: 'no-store' });
                const data = await res.json();
                if (!data.ok) throw new Error(data.error || ('HTTP ' + res.status));
                render(data);
                $('awStatus').textContent = '';
            } catch (e) { $('awStatus').textContent = '錯誤：' + e.message; }
        }
        $('awLoad').addEventListener('click', load);
        load();
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
            const PROXY_URL = 'NPW_Alarm.aspx?op=chat';
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
