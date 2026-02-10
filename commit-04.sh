#!/bin/bash
# ============================================
# COMMIT 4: Dictionary manager with projects, export/import
# ============================================
# Run from inside prompt-mask/

cat > app/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎭 prompt-mask</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Mono:wght@400;500&family=Anybody:wght@400;600;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: #0e0e10;
            --surface: #18181b;
            --surface-hover: #1e1e22;
            --border: #2a2a2f;
            --text: #e4e4e7;
            --text-muted: #71717a;
            --accent: #f59e0b;
            --accent-dim: #b45309;
            --anon: #f59e0b;
            --block: #ef4444;
            --random: #8b5cf6;
            --success: #22c55e;
            --radius: 8px;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'DM Mono', monospace;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* ── Privacy banner ── */
        .privacy-banner {
            background: linear-gradient(90deg, rgba(245,158,11,0.06), rgba(139,92,246,0.06));
            border-bottom: 1px solid var(--border);
            padding: 6px 20px;
            display: flex; align-items: center; justify-content: center;
            gap: 8px; font-size: 11px; color: var(--text-muted);
        }
        .privacy-banner .dot {
            width: 6px; height: 6px; background: var(--success);
            border-radius: 50%; animation: pulse 2s ease-in-out infinite;
        }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }

        /* ── Header ── */
        header {
            padding: 24px 40px 0;
            display: flex; align-items: center; justify-content: space-between;
        }
        .header-left h1 {
            font-family: 'Anybody', sans-serif;
            font-weight: 800; font-size: 28px; letter-spacing: -1px;
        }
        .header-left .tagline {
            color: var(--text-muted); font-size: 12px; margin-top: 4px;
        }
        .header-right { display: flex; gap: 8px; align-items: center; }

        /* ── Project selector ── */
        .project-selector {
            display: flex; align-items: center; gap: 8px;
        }
        .project-selector label {
            font-size: 11px; color: var(--text-muted);
            text-transform: uppercase; letter-spacing: 1px;
        }
        .project-selector select {
            font-family: 'DM Mono', monospace;
            font-size: 12px; padding: 5px 10px;
            background: var(--surface); color: var(--text);
            border: 1px solid var(--border); border-radius: var(--radius);
            cursor: pointer; outline: none;
        }
        .project-selector select:focus { border-color: var(--accent-dim); }

        /* ── Workspace ── */
        .workspace {
            flex: 1; display: grid; grid-template-columns: 1fr 1fr;
            padding: 20px 40px; gap: 0; min-height: 0;
        }
        .panel { display: flex; flex-direction: column; min-height: 300px; }
        .panel:first-child { padding-right: 16px; border-right: 1px solid var(--border); }
        .panel:last-child { padding-left: 16px; }
        .panel-header {
            display: flex; align-items: center;
            justify-content: space-between; margin-bottom: 8px;
        }
        .panel-label {
            font-family: 'Anybody', sans-serif; font-weight: 600;
            font-size: 11px; text-transform: uppercase;
            letter-spacing: 1.5px; color: var(--text-muted);
        }

        textarea {
            flex: 1; background: var(--surface);
            border: 1px solid var(--border); border-radius: var(--radius);
            color: var(--text); font-family: 'DM Mono', monospace;
            font-size: 13px; line-height: 1.7; padding: 16px;
            resize: none; outline: none; transition: border-color 0.2s;
        }
        textarea:focus { border-color: var(--accent-dim); }
        textarea::placeholder { color: var(--text-muted); font-style: italic; }

        /* ── Buttons ── */
        button {
            font-family: 'DM Mono', monospace; font-size: 11px;
            padding: 6px 14px; border-radius: var(--radius);
            border: 1px solid var(--border); background: var(--surface);
            color: var(--text); cursor: pointer; transition: all 0.15s;
        }
        button:hover { background: var(--surface-hover); border-color: var(--accent-dim); }
        button.primary {
            background: var(--accent); color: var(--bg);
            border-color: var(--accent); font-weight: 500;
        }
        button.primary:hover { background: var(--accent-dim); border-color: var(--accent-dim); }
        button.copied { border-color: var(--success); color: var(--success); }
        button.danger { border-color: var(--block); color: var(--block); }
        button.danger:hover { background: rgba(239,68,68,0.1); }

        /* ── Toolbar ── */
        .toolbar { display: flex; gap: 4px; margin-bottom: 8px; flex-wrap: wrap; }
        .toolbar button { display: flex; align-items: center; gap: 5px; }
        .marker-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
        .marker-dot.anon { background: var(--anon); }
        .marker-dot.block { background: var(--block); }
        .marker-dot.random { background: var(--random); }
        .shortcut { color: var(--text-muted); font-size: 9px; }

        /* ── Action bar ── */
        .action-bar {
            display: flex; align-items: center; justify-content: center;
            gap: 12px; padding: 0 40px 12px;
        }
        .action-bar button {
            font-family: 'Anybody', sans-serif;
            font-weight: 600; font-size: 13px; padding: 10px 32px;
        }
        .action-bar .arrow { color: var(--text-muted); font-size: 18px; }

        /* ── Context menu ── */
        .ctx-menu {
            display: none; position: fixed; background: var(--surface);
            border: 1px solid var(--border); border-radius: var(--radius);
            padding: 4px 0; min-width: 210px; z-index: 1000;
            box-shadow: 0 8px 30px rgba(0,0,0,0.5);
        }
        .ctx-menu.visible { display: block; animation: ctxIn 0.12s ease-out; }
        @keyframes ctxIn {
            from { opacity:0; transform:scale(0.95) translateY(-4px); }
            to { opacity:1; transform:scale(1) translateY(0); }
        }
        .ctx-menu button {
            display: flex; align-items: center; gap: 8px;
            width: 100%; border: none; border-radius: 0;
            padding: 8px 14px; font-size: 12px;
            background: transparent; text-align: left;
        }
        .ctx-menu button:hover { background: var(--surface-hover); }
        .ctx-menu .ctx-shortcut { margin-left: auto; color: var(--text-muted); font-size: 10px; }

        /* ── Stats bar ── */
        .stats-bar {
            border-top: 1px solid var(--border); padding: 8px 40px;
            display: flex; gap: 24px; font-size: 11px; color: var(--text-muted);
        }
        .stat-item span { color: var(--text); font-weight: 500; }

        /* ── Dictionary panel ── */
        .dict-panel {
            border-top: 1px solid var(--border);
            max-height: 0; overflow: hidden;
            transition: max-height 0.3s ease;
        }
        .dict-panel.open { max-height: 600px; overflow-y: auto; }

        .dict-header {
            display: flex; align-items: center; justify-content: space-between;
            padding: 12px 40px; position: sticky; top: 0;
            background: var(--bg); z-index: 1;
        }
        .dict-header .dict-title {
            font-family: 'Anybody', sans-serif; font-weight: 600;
            font-size: 11px; text-transform: uppercase;
            letter-spacing: 1.5px; color: var(--text-muted);
        }
        .dict-actions { display: flex; gap: 6px; }

        .dict-table {
            width: 100%; padding: 0 40px 16px;
            border-collapse: collapse;
        }
        .dict-table th {
            text-align: left; font-size: 10px; color: var(--text-muted);
            text-transform: uppercase; letter-spacing: 1px;
            padding: 6px 12px; border-bottom: 1px solid var(--border);
        }
        .dict-table td {
            padding: 6px 12px; font-size: 12px;
            border-bottom: 1px solid var(--border);
        }
        .dict-table tr:hover { background: var(--surface-hover); }
        .dict-table .type-badge {
            font-size: 9px; padding: 2px 6px;
            border-radius: 4px; text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .type-badge.identity { background: var(--anon-bg, rgba(245,158,11,0.12)); color: var(--anon); }
        .type-badge.amount { background: var(--random-bg, rgba(139,92,246,0.12)); color: var(--random); }
        .type-badge.date { background: rgba(34,197,94,0.12); color: var(--success); }
        .type-badge.text { background: rgba(113,113,122,0.12); color: var(--text-muted); }
        .type-badge.blocked { background: rgba(239,68,68,0.12); color: var(--block); }

        .dict-table .del-btn {
            background: none; border: none; color: var(--text-muted);
            cursor: pointer; padding: 2px 6px; font-size: 14px;
            border-radius: 4px;
        }
        .dict-table .del-btn:hover { color: var(--block); background: rgba(239,68,68,0.1); }

        .dict-empty {
            text-align: center; padding: 24px 40px;
            color: var(--text-muted); font-size: 12px; font-style: italic;
        }

        /* ── Add entry row ── */
        .add-entry {
            display: flex; gap: 8px; padding: 0 40px 12px;
            align-items: center;
        }
        .add-entry input {
            font-family: 'DM Mono', monospace; font-size: 12px;
            padding: 5px 10px; background: var(--surface);
            color: var(--text); border: 1px solid var(--border);
            border-radius: var(--radius); outline: none; flex: 1;
        }
        .add-entry input:focus { border-color: var(--accent-dim); }
        .add-entry input::placeholder { color: var(--text-muted); }

        /* ── Modal ── */
        .modal-overlay {
            display: none; position: fixed; inset: 0;
            background: rgba(0,0,0,0.6); z-index: 2000;
            align-items: center; justify-content: center;
        }
        .modal-overlay.visible { display: flex; }
        .modal {
            background: var(--surface); border: 1px solid var(--border);
            border-radius: 12px; padding: 24px; min-width: 360px;
            max-width: 500px;
        }
        .modal h3 {
            font-family: 'Anybody', sans-serif; font-weight: 600;
            font-size: 16px; margin-bottom: 16px;
        }
        .modal input[type="text"] {
            font-family: 'DM Mono', monospace; font-size: 13px;
            padding: 8px 12px; background: var(--bg); color: var(--text);
            border: 1px solid var(--border); border-radius: var(--radius);
            outline: none; width: 100%; margin-bottom: 12px;
        }
        .modal input[type="text"]:focus { border-color: var(--accent-dim); }
        .modal-actions { display: flex; gap: 8px; justify-content: flex-end; margin-top: 16px; }

        /* ── Hidden file input ── */
        #importFile { display: none; }

        /* ── Responsive ── */
        @media (max-width: 768px) {
            .workspace { grid-template-columns: 1fr; }
            .panel:first-child { padding-right: 0; border-right: none; padding-bottom: 16px; border-bottom: 1px solid var(--border); }
            .panel:last-child { padding-left: 0; padding-top: 16px; }
            header, .action-bar, .stats-bar, .dict-header, .dict-table, .add-entry { padding-left: 20px; padding-right: 20px; }
            .workspace { padding: 20px; }
            header { flex-direction: column; align-items: flex-start; gap: 12px; }
        }
    </style>
</head>
<body>

<!-- Privacy banner -->
<div class="privacy-banner">
    <span class="dot"></span>
    100% LOCAL — No data leaves your browser. No server, no account, no tracking.
    <span style="margin-left:4px; opacity:0.5">Press F12 → Network tab to verify.</span>
</div>

<!-- Header -->
<header>
    <div class="header-left">
        <h1>🎭 prompt-mask</h1>
        <p class="tagline">Anonymize your prompts before sending them to AI.</p>
    </div>
    <div class="header-right">
        <div class="project-selector">
            <label>Project:</label>
            <select id="projectSelect" onchange="switchProject()"></select>
            <button onclick="showNewProjectModal()" title="New project">+</button>
            <button onclick="deleteCurrentProject()" class="danger" title="Delete project">×</button>
        </div>
    </div>
</header>

<!-- Workspace -->
<div class="workspace">
    <div class="panel">
        <div class="panel-header">
            <span class="panel-label">Your prompt</span>
        </div>
        <div class="toolbar">
            <button onclick="wrapSelection('anon')" title="Anonymize selection">
                <span class="marker-dot anon"></span> Anonymize <span class="shortcut">Ctrl+1</span>
            </button>
            <button onclick="wrapSelection('block')" title="Block selection">
                <span class="marker-dot block"></span> Block <span class="shortcut">Ctrl+2</span>
            </button>
            <button onclick="wrapSelection('random')" title="Randomize selection">
                <span class="marker-dot random"></span> Randomize <span class="shortcut">Ctrl+3</span>
            </button>
        </div>
        <textarea id="input" placeholder="Type or paste your prompt here...&#10;&#10;Mark sensitive data:&#10;  Select text → right-click → choose action&#10;  Or type: ***{name}  ---{secret}  +++{amount}&#10;  Or use toolbar buttons / Ctrl+1,2,3"></textarea>
    </div>
    <div class="panel">
        <div class="panel-header">
            <span class="panel-label">Masked output</span>
            <button id="copyBtn" onclick="copyOutput()">Copy</button>
        </div>
        <div class="toolbar" style="visibility:hidden"></div>
        <textarea id="output" readonly placeholder="Masked prompt will appear here..."></textarea>
    </div>
</div>

<!-- Action bar -->
<div class="action-bar">
    <button class="primary seal-btn" onclick="seal()">⬇ SEAL</button>
    <span class="arrow">⇄</span>
    <button class="seal-btn" onclick="unseal()">⬆ UNSEAL</button>
    <button style="margin-left:24px" onclick="clearAll()">Clear</button>
</div>

<!-- Stats bar -->
<div class="stats-bar">
    <div class="stat-item">Markers: <span id="statMarkers">0</span></div>
    <div class="stat-item">Dictionary: <span id="statDict">0</span> entries</div>
    <div class="stat-item">
        <span class="marker-dot anon"></span>&nbsp;<span id="statAnon">0</span>&emsp;
        <span class="marker-dot block"></span>&nbsp;<span id="statBlock">0</span>&emsp;
        <span class="marker-dot random"></span>&nbsp;<span id="statRandom">0</span>
    </div>
    <div style="margin-left:auto">
        <button onclick="toggleDict()" id="dictToggleBtn">📖 Dictionary</button>
    </div>
</div>

<!-- Dictionary panel -->
<div class="dict-panel" id="dictPanel">
    <div class="dict-header">
        <span class="dict-title">📖 Dictionary — <span id="dictProjectLabel"></span></span>
        <div class="dict-actions">
            <button onclick="exportDict()">Export</button>
            <button onclick="document.getElementById('importFile').click()">Import</button>
            <input type="file" id="importFile" accept=".json" onchange="importDict(event)">
            <button class="danger" onclick="clearDict()">Clear all</button>
        </div>
    </div>
    <div class="add-entry">
        <input type="text" id="addReal" placeholder="Real value...">
        <input type="text" id="addFake" placeholder="Masked value...">
        <button onclick="addManualEntry()">+ Add</button>
    </div>
    <div id="dictContent"></div>
</div>

<!-- Context menu -->
<div class="ctx-menu" id="ctxMenu">
    <button onclick="wrapSelection('anon')">
        <span class="marker-dot anon"></span> Anonymize <span class="ctx-shortcut">Ctrl+1</span>
    </button>
    <button onclick="wrapSelection('block')">
        <span class="marker-dot block"></span> Block <span class="ctx-shortcut">Ctrl+2</span>
    </button>
    <button onclick="wrapSelection('random')">
        <span class="marker-dot random"></span> Randomize <span class="ctx-shortcut">Ctrl+3</span>
    </button>
</div>

<!-- New project modal -->
<div class="modal-overlay" id="newProjectModal">
    <div class="modal">
        <h3>New Project</h3>
        <input type="text" id="newProjectName" placeholder="Project name..." onkeydown="if(event.key==='Enter')createProject()">
        <div class="modal-actions">
            <button onclick="closeModal()">Cancel</button>
            <button class="primary" onclick="createProject()">Create</button>
        </div>
    </div>
</div>

<script>
// ════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════
let currentProject = 'default';
let projects = {};   // { projectName: { dict: {real→fake}, rdict: {fake→real}, types: {real→type} } }

// ════════════════════════════════════════════
// FAKE DATA POOLS
// ════════════════════════════════════════════
const FAKE_NAMES = [
    "Alex Morgan", "Sam Rivera", "Jordan Chen", "Casey Brooks",
    "Riley Park", "Quinn Foster", "Avery Lane", "Taylor Nash",
    "Morgan Ellis", "Jamie Cross", "Drew Palmer", "Blake Warren",
    "Reese Conrad", "Parker Stone", "Sage Mitchell", "Robin Clarke"
];
const FAKE_COMPANIES = [
    "Vertex Labs", "NovaBridge", "Apex Dynamics", "Cobalt Systems",
    "IronLeaf Corp", "Prism Works", "Zenith Group", "Atlas Digital",
    "Onyx Partners", "Helix Solutions", "Lunar Industries", "Forge & Co"
];
const FAKE_EMAILS = [
    "contact@vertex-labs.com", "info@novabridge.io", "hello@apex-dyn.com",
    "team@cobalt-sys.com", "admin@ironleaf.co", "mail@prismworks.io"
];
const FAKE_PROJECTS = [
    "Project Horizon", "Project Nebula", "Project Titan", "Project Echo",
    "Project Meridian", "Project Onyx", "Project Vanguard", "Project Apex"
];

let nameIdx = 0, companyIdx = 0, emailIdx = 0, projectIdx = 0;

// ════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════
function getDict() { return projects[currentProject]?.dict || {}; }
function getRdict() { return projects[currentProject]?.rdict || {}; }
function getTypes() { return projects[currentProject]?.types || {}; }

function setMapping(real, fake, type) {
    if (!projects[currentProject]) initProject(currentProject);
    projects[currentProject].dict[real] = fake;
    projects[currentProject].rdict[fake] = real;
    projects[currentProject].types[real] = type || 'identity';
}

function removeMapping(real) {
    const p = projects[currentProject];
    if (!p) return;
    const fake = p.dict[real];
    delete p.dict[real];
    delete p.types[real];
    if (fake) delete p.rdict[fake];
}

function initProject(name) {
    if (!projects[name]) {
        projects[name] = { dict: {}, rdict: {}, types: {} };
    }
}

// ════════════════════════════════════════════
// TYPE DETECTION + FAKE GENERATION
// ════════════════════════════════════════════
function detectType(value) {
    const v = value.trim();
    if (/^[\w.+-]+@[\w-]+\.[\w.]+$/.test(v)) return 'email';
    if (/\b(project|projet)\s/i.test(v)) return 'project';
    if (/\b(inc|corp|ltd|sas|sarl|gmbh|llc|group|labs?|co)\b/i.test(v)
        || /[A-Z].*[A-Z].*(&|\band\b)/.test(v)) return 'company';
    if (/^[\d\s.,]+[€$£¥kKmM%]?$/.test(v)) return 'amount';
    return 'name';
}

function generateFake(value, type) {
    switch (type) {
        case 'email':    return FAKE_EMAILS[emailIdx++ % FAKE_EMAILS.length];
        case 'company':  return FAKE_COMPANIES[companyIdx++ % FAKE_COMPANIES.length];
        case 'project':  return FAKE_PROJECTS[projectIdx++ % FAKE_PROJECTS.length];
        case 'amount':   return randomizeValue(value);
        default:         return FAKE_NAMES[nameIdx++ % FAKE_NAMES.length];
    }
}

function randomizeValue(value) {
    const v = value.trim();

    // Try as number/amount
    const amountMatch = v.match(/^([^\d]*)(\d[\d\s.,]*)(\s*[€$£¥kKmM%]*.*)$/);
    if (amountMatch) {
        const prefix = amountMatch[1];
        const numStr = amountMatch[2].replace(/[\s,]/g, '');
        const suffix = amountMatch[3];
        const num = parseFloat(numStr);
        if (!isNaN(num)) {
            const factor = 0.7 + Math.random() * 0.6;
            return prefix + Math.round(num * factor) + suffix;
        }
    }

    // Try as date (dd/mm/yyyy, mm/dd/yyyy, yyyy-mm-dd)
    const dateMatch = v.match(/^(\d{1,4})([\/-])(\d{1,2})\2(\d{1,4})$/);
    if (dateMatch) {
        const offset = Math.floor(Math.random() * 60) - 30;
        const parts = [dateMatch[1], dateMatch[3], dateMatch[4]].map(Number);
        const sep = dateMatch[2];
        let d;
        if (parts[2] > 31) {
            d = new Date(parts[2], parts[1] - 1, parts[0]);
        } else {
            d = new Date(parts[0], parts[1] - 1, parts[2]);
        }
        if (!isNaN(d.getTime())) {
            d.setDate(d.getDate() + offset);
            const pad = n => String(n).padStart(2, '0');
            if (parts[2] > 31) {
                return pad(d.getDate()) + sep + pad(d.getMonth()+1) + sep + d.getFullYear();
            } else {
                return d.getFullYear() + sep + pad(d.getMonth()+1) + sep + pad(d.getDate());
            }
        }
    }

    // Any other text: shuffle preserving shape
    const chars = v.split('');
    for (let i = chars.length - 1; i > 0; i--) {
        const c = chars[i];
        if (/[a-z]/.test(c)) chars[i] = String.fromCharCode(97 + Math.floor(Math.random() * 26));
        else if (/[A-Z]/.test(c)) chars[i] = String.fromCharCode(65 + Math.floor(Math.random() * 26));
        else if (/[0-9]/.test(c)) chars[i] = String(Math.floor(Math.random() * 10));
    }
    return chars.join('');
}

// ════════════════════════════════════════════
// SEAL
// ════════════════════════════════════════════
function seal() {
    const input = document.getElementById('input').value;
    let output = input;
    let anonCount = 0, blockCount = 0, randomCount = 0;
    const dict = getDict();

    output = output.replace(/\*\*\*\{([^}]+)\}/g, (_, value) => {
        anonCount++;
        if (dict[value]) return dict[value];
        const type = detectType(value);
        const fake = generateFake(value, type);
        setMapping(value, fake, type);
        return fake;
    });

    output = output.replace(/---\{([^}]*)\}/g, (_, value) => {
        blockCount++;
        if (value) setMapping(value, '[REDACTED]', 'blocked');
        return '[REDACTED]';
    });

    output = output.replace(/\+\+\+\{([^}]+)\}/g, (_, value) => {
        randomCount++;
        if (dict[value]) return dict[value];
        const fake = randomizeValue(value);
        const type = /\d/.test(value) ? (/[€$£¥%]/.test(value) ? 'amount' : 'date') : 'text';
        setMapping(value, fake, type);
        return fake;
    });

    document.getElementById('output').value = output;
    updateStats(anonCount, blockCount, randomCount);
    saveAll();
    renderDict();
}

// ════════════════════════════════════════════
// UNSEAL
// ════════════════════════════════════════════
function unseal() {
    const input = document.getElementById('input').value;
    let output = input;
    const rdict = getRdict();
    const fakes = Object.keys(rdict).sort((a, b) => b.length - a.length);
    for (const fake of fakes) {
        output = output.split(fake).join(rdict[fake]);
    }
    document.getElementById('output').value = output;
}

// ════════════════════════════════════════════
// WRAP SELECTION
// ════════════════════════════════════════════
function wrapSelection(type) {
    const textarea = document.getElementById('input');
    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const selected = textarea.value.substring(start, end);
    hideContextMenu();
    if (!selected) return;
    const markers = { anon: '***', block: '---', random: '+++' };
    const wrapped = markers[type] + '{' + selected + '}';
    textarea.value = textarea.value.substring(0, start) + wrapped + textarea.value.substring(end);
    const newPos = start + wrapped.length;
    textarea.selectionStart = newPos;
    textarea.selectionEnd = newPos;
    textarea.focus();
}

// ════════════════════════════════════════════
// CONTEXT MENU
// ════════════════════════════════════════════
const ctxMenu = document.getElementById('ctxMenu');
document.getElementById('input').addEventListener('contextmenu', (e) => {
    const textarea = document.getElementById('input');
    const selected = textarea.value.substring(textarea.selectionStart, textarea.selectionEnd);
    if (selected) {
        e.preventDefault();
        ctxMenu.style.left = e.clientX + 'px';
        ctxMenu.style.top = e.clientY + 'px';
        ctxMenu.classList.add('visible');
    }
});
document.addEventListener('click', hideContextMenu);
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') hideContextMenu(); });
function hideContextMenu() { ctxMenu.classList.remove('visible'); }

// ════════════════════════════════════════════
// KEYBOARD SHORTCUTS
// ════════════════════════════════════════════
document.addEventListener('keydown', (e) => {
    if (e.ctrlKey || e.metaKey) {
        if (e.key === '1') { e.preventDefault(); wrapSelection('anon'); }
        if (e.key === '2') { e.preventDefault(); wrapSelection('block'); }
        if (e.key === '3') { e.preventDefault(); wrapSelection('random'); }
    }
});

// ════════════════════════════════════════════
// COPY / CLEAR / STATS
// ════════════════════════════════════════════
function copyOutput() {
    const output = document.getElementById('output');
    navigator.clipboard.writeText(output.value).then(() => {
        const btn = document.getElementById('copyBtn');
        btn.textContent = '✓ Copied';
        btn.classList.add('copied');
        setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 1500);
    });
}

function clearAll() {
    document.getElementById('input').value = '';
    document.getElementById('output').value = '';
    updateStats(0, 0, 0);
}

function updateStats(anon, block, random) {
    document.getElementById('statMarkers').textContent = anon + block + random;
    document.getElementById('statDict').textContent = Object.keys(getDict()).length;
    document.getElementById('statAnon').textContent = anon;
    document.getElementById('statBlock').textContent = block;
    document.getElementById('statRandom').textContent = random;
}

// ════════════════════════════════════════════
// DICTIONARY PANEL
// ════════════════════════════════════════════
function toggleDict() {
    const panel = document.getElementById('dictPanel');
    panel.classList.toggle('open');
    renderDict();
}

function renderDict() {
    const dict = getDict();
    const types = getTypes();
    const container = document.getElementById('dictContent');
    const entries = Object.entries(dict);

    document.getElementById('dictProjectLabel').textContent = currentProject;
    document.getElementById('statDict').textContent = entries.length;

    if (entries.length === 0) {
        container.innerHTML = '<div class="dict-empty">No entries yet. Seal a prompt or add entries manually.</div>';
        return;
    }

    let html = '<table class="dict-table"><thead><tr><th>Real</th><th>Masked</th><th>Type</th><th></th></tr></thead><tbody>';
    for (const [real, fake] of entries) {
        const type = types[real] || 'identity';
        html += `<tr>
            <td>${escHtml(real)}</td>
            <td>${escHtml(fake)}</td>
            <td><span class="type-badge ${type}">${type}</span></td>
            <td><button class="del-btn" onclick="deleteEntry('${escAttr(real)}')" title="Delete">×</button></td>
        </tr>`;
    }
    html += '</tbody></table>';
    container.innerHTML = html;
}

function escHtml(s) { return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function escAttr(s) { return s.replace(/\\/g,'\\\\').replace(/'/g,"\\'"); }

function deleteEntry(real) {
    removeMapping(real);
    saveAll();
    renderDict();
    updateStats(0, 0, 0);
}

function clearDict() {
    if (!confirm('Clear all entries for "' + currentProject + '"?')) return;
    projects[currentProject] = { dict: {}, rdict: {}, types: {} };
    saveAll();
    renderDict();
    updateStats(0, 0, 0);
}

function addManualEntry() {
    const real = document.getElementById('addReal').value.trim();
    const fake = document.getElementById('addFake').value.trim();
    if (!real || !fake) return;
    const type = detectType(real);
    setMapping(real, fake, type);
    document.getElementById('addReal').value = '';
    document.getElementById('addFake').value = '';
    saveAll();
    renderDict();
    updateStats(0, 0, 0);
}

// ════════════════════════════════════════════
// EXPORT / IMPORT
// ════════════════════════════════════════════
function exportDict() {
    const data = {
        project: currentProject,
        version: 1,
        exported: new Date().toISOString(),
        entries: Object.entries(getDict()).map(([real, fake]) => ({
            real, fake, type: getTypes()[real] || 'identity'
        }))
    };
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `prompt-mask_${currentProject}_${new Date().toISOString().slice(0,10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
}

function importDict(event) {
    const file = event.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (e) => {
        try {
            const data = JSON.parse(e.target.result);
            if (!data.entries || !Array.isArray(data.entries)) {
                alert('Invalid file format.');
                return;
            }
            const targetProject = data.project || currentProject;
            if (!projects[targetProject]) initProject(targetProject);
            for (const entry of data.entries) {
                projects[targetProject].dict[entry.real] = entry.fake;
                projects[targetProject].rdict[entry.fake] = entry.real;
                projects[targetProject].types[entry.real] = entry.type || 'identity';
            }
            if (targetProject !== currentProject) {
                currentProject = targetProject;
                renderProjectSelect();
            }
            saveAll();
            renderDict();
            updateStats(0, 0, 0);
        } catch (err) {
            alert('Error reading file: ' + err.message);
        }
    };
    reader.readAsText(file);
    event.target.value = '';
}

// ════════════════════════════════════════════
// PROJECTS
// ════════════════════════════════════════════
function renderProjectSelect() {
    const select = document.getElementById('projectSelect');
    select.innerHTML = '';
    for (const name of Object.keys(projects)) {
        const opt = document.createElement('option');
        opt.value = name;
        opt.textContent = name;
        if (name === currentProject) opt.selected = true;
        select.appendChild(opt);
    }
}

function switchProject() {
    currentProject = document.getElementById('projectSelect').value;
    saveAll();
    renderDict();
    updateStats(0, 0, 0);
}

function showNewProjectModal() {
    document.getElementById('newProjectModal').classList.add('visible');
    document.getElementById('newProjectName').value = '';
    document.getElementById('newProjectName').focus();
}

function closeModal() {
    document.getElementById('newProjectModal').classList.remove('visible');
}

function createProject() {
    const name = document.getElementById('newProjectName').value.trim();
    if (!name) return;
    if (projects[name]) { alert('Project already exists.'); return; }
    initProject(name);
    currentProject = name;
    saveAll();
    renderProjectSelect();
    renderDict();
    updateStats(0, 0, 0);
    closeModal();
}

function deleteCurrentProject() {
    if (currentProject === 'default') { alert('Cannot delete the default project.'); return; }
    if (!confirm('Delete project "' + currentProject + '" and all its entries?')) return;
    delete projects[currentProject];
    currentProject = 'default';
    saveAll();
    renderProjectSelect();
    renderDict();
    updateStats(0, 0, 0);
}

// ════════════════════════════════════════════
// PERSISTENCE
// ════════════════════════════════════════════
function saveAll() {
    try {
        localStorage.setItem('promptmask_projects', JSON.stringify(projects));
        localStorage.setItem('promptmask_current', currentProject);
    } catch (e) { /* silent */ }
}

function loadAll() {
    try {
        const p = localStorage.getItem('promptmask_projects');
        const c = localStorage.getItem('promptmask_current');
        if (p) projects = JSON.parse(p);
        if (c && projects[c]) currentProject = c;

        // Migrate from old format
        const oldDict = localStorage.getItem('promptmask_dict');
        const oldRdict = localStorage.getItem('promptmask_rdict');
        if (oldDict && !projects['default']?.dict) {
            initProject('default');
            projects['default'].dict = JSON.parse(oldDict);
            if (oldRdict) projects['default'].rdict = JSON.parse(oldRdict);
            localStorage.removeItem('promptmask_dict');
            localStorage.removeItem('promptmask_rdict');
            saveAll();
        }
    } catch (e) { /* silent */ }

    if (!projects['default']) initProject('default');
    renderProjectSelect();
    renderDict();
    updateStats(0, 0, 0);
}

// ════════════════════════════════════════════
// INIT
// ════════════════════════════════════════════
loadAll();
</script>
</body>
</html>
HTMLEOF

# ============================================
# Git commit
# ============================================
git add -A
git commit -m "feat: dictionary manager with projects, export/import

- Dictionary panel (toggle with 📖 button)
  - View all mappings in a table (real → masked → type)
  - Add entries manually
  - Delete individual entries
  - Clear all entries
- Project/context system
  - Switch between projects (separate dictionaries)
  - Create / delete projects
  - Default project always exists
- Export dictionary as JSON file
- Import dictionary from JSON file (auto-creates project)
- Migration from old localStorage format
- Type badges (identity, amount, date, text, blocked)
- Improved type detection for +++{} randomize entries"

echo ""
echo "✅ Commit 4 done!"
echo "Refresh app/index.html to test."
echo ""
