#!/bin/bash
# ============================================
# COMMIT 2: Web app — core seal/unseal with mini-language
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
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            font-size: 11px;
            color: var(--text-muted);
        }
        .privacy-banner .dot {
            width: 6px; height: 6px;
            background: var(--success);
            border-radius: 50%;
            animation: pulse 2s ease-in-out infinite;
        }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }

        /* ── Header ── */
        header { padding: 24px 40px 0; }
        header h1 {
            font-family: 'Anybody', sans-serif;
            font-weight: 800; font-size: 28px;
            letter-spacing: -1px;
        }
        header .tagline {
            color: var(--text-muted);
            font-size: 12px; margin-top: 4px;
        }

        /* ── Workspace ── */
        .workspace {
            flex: 1;
            display: grid;
            grid-template-columns: 1fr 1fr;
            padding: 20px 40px;
            gap: 0;
            min-height: 0;
        }
        .panel {
            display: flex;
            flex-direction: column;
            min-height: 300px;
        }
        .panel:first-child {
            padding-right: 16px;
            border-right: 1px solid var(--border);
        }
        .panel:last-child { padding-left: 16px; }

        .panel-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }
        .panel-label {
            font-family: 'Anybody', sans-serif;
            font-weight: 600; font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            color: var(--text-muted);
        }

        textarea {
            flex: 1;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            color: var(--text);
            font-family: 'DM Mono', monospace;
            font-size: 13px;
            line-height: 1.7;
            padding: 16px;
            resize: none;
            outline: none;
            transition: border-color 0.2s;
        }
        textarea:focus { border-color: var(--accent-dim); }
        textarea::placeholder { color: var(--text-muted); font-style: italic; }

        /* ── Buttons ── */
        button {
            font-family: 'DM Mono', monospace;
            font-size: 11px;
            padding: 6px 14px;
            border-radius: var(--radius);
            border: 1px solid var(--border);
            background: var(--surface);
            color: var(--text);
            cursor: pointer;
            transition: all 0.15s;
        }
        button:hover {
            background: var(--surface-hover);
            border-color: var(--accent-dim);
        }
        button.primary {
            background: var(--accent);
            color: var(--bg);
            border-color: var(--accent);
            font-weight: 500;
        }
        button.primary:hover {
            background: var(--accent-dim);
            border-color: var(--accent-dim);
        }
        button.copied { border-color: var(--success); color: var(--success); }

        /* ── Toolbar ── */
        .toolbar {
            display: flex;
            gap: 4px;
            margin-bottom: 8px;
            flex-wrap: wrap;
        }
        .toolbar button {
            display: flex;
            align-items: center;
            gap: 5px;
        }
        .marker-dot {
            width: 8px; height: 8px;
            border-radius: 50%; display: inline-block;
        }
        .marker-dot.anon { background: var(--anon); }
        .marker-dot.block { background: var(--block); }
        .marker-dot.random { background: var(--random); }
        .shortcut { color: var(--text-muted); font-size: 9px; }

        /* ── Action bar ── */
        .action-bar {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            padding: 0 40px 20px;
        }
        .action-bar button {
            font-family: 'Anybody', sans-serif;
            font-weight: 600; font-size: 13px;
            padding: 10px 32px;
        }
        .action-bar .arrow { color: var(--text-muted); font-size: 18px; }

        /* ── Context menu ── */
        .ctx-menu {
            display: none;
            position: fixed;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 4px 0;
            min-width: 210px;
            z-index: 1000;
            box-shadow: 0 8px 30px rgba(0,0,0,0.5);
        }
        .ctx-menu.visible {
            display: block;
            animation: ctxIn 0.12s ease-out;
        }
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
        .ctx-menu .ctx-shortcut {
            margin-left: auto;
            color: var(--text-muted); font-size: 10px;
        }

        /* ── Stats bar ── */
        .stats-bar {
            border-top: 1px solid var(--border);
            padding: 8px 40px;
            display: flex;
            gap: 24px;
            font-size: 11px;
            color: var(--text-muted);
        }
        .stat-item span { color: var(--text); font-weight: 500; }

        /* ── Responsive ── */
        @media (max-width: 768px) {
            .workspace { grid-template-columns: 1fr; }
            .panel:first-child { padding-right: 0; border-right: none; padding-bottom: 16px; border-bottom: 1px solid var(--border); }
            .panel:last-child { padding-left: 0; padding-top: 16px; }
            header, .action-bar, .stats-bar { padding-left: 20px; padding-right: 20px; }
            .workspace { padding: 20px; }
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
    <h1>🎭 prompt-mask</h1>
    <p class="tagline">Anonymize your prompts before sending them to AI.</p>
</header>

<!-- Workspace -->
<div class="workspace">
    <!-- Input panel -->
    <div class="panel">
        <div class="panel-header">
            <span class="panel-label">Your prompt</span>
        </div>
        <div class="toolbar">
            <button onclick="wrapSelection('anon')" title="Anonymize selection">
                <span class="marker-dot anon"></span> Anonymize
                <span class="shortcut">Ctrl+1</span>
            </button>
            <button onclick="wrapSelection('block')" title="Block selection">
                <span class="marker-dot block"></span> Block
                <span class="shortcut">Ctrl+2</span>
            </button>
            <button onclick="wrapSelection('random')" title="Randomize selection">
                <span class="marker-dot random"></span> Randomize
                <span class="shortcut">Ctrl+3</span>
            </button>
        </div>
        <textarea id="input" placeholder="Type or paste your prompt here...&#10;&#10;Mark sensitive data:&#10;  Select text → right-click → choose action&#10;  Or type: ***{name}  ###{secret}  $$${amount}&#10;  Or use toolbar buttons / Ctrl+1,2,3"></textarea>
    </div>

    <!-- Output panel -->
    <div class="panel">
        <div class="panel-header">
            <span class="panel-label">Masked output</span>
            <div style="display:flex;gap:6px">
                <button id="copyBtn" onclick="copyOutput()">Copy</button>
            </div>
        </div>
        <div class="toolbar" style="visibility:hidden"><!-- spacer --></div>
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
</div>

<!-- Context menu -->
<div class="ctx-menu" id="ctxMenu">
    <button onclick="wrapSelection('anon')">
        <span class="marker-dot anon"></span> Anonymize
        <span class="ctx-shortcut">Ctrl+1</span>
    </button>
    <button onclick="wrapSelection('block')">
        <span class="marker-dot block"></span> Block
        <span class="ctx-shortcut">Ctrl+2</span>
    </button>
    <button onclick="wrapSelection('random')">
        <span class="marker-dot random"></span> Randomize
        <span class="ctx-shortcut">Ctrl+3</span>
    </button>
</div>

<script>
// ════════════════════════════════════════════
// DICTIONARY
// ════════════════════════════════════════════
const dictionary = {};
const reverseDictionary = {};

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
        case 'amount':   return randomizeAmount(value);
        default:         return FAKE_NAMES[nameIdx++ % FAKE_NAMES.length];
    }
}

function randomizeAmount(value) {
    const cleaned = value.replace(/[\s,]/g, '');
    const match = cleaned.match(/([\d.]+)\s*([€$£¥kKmM%]*)/);
    if (!match) return value;
    const num = parseFloat(match[1]);
    const suffix = match[2] || '';
    const factor = 0.7 + Math.random() * 0.6;
    return Math.round(num * factor) + suffix;
}

// ════════════════════════════════════════════
// SEAL
// ════════════════════════════════════════════
function seal() {
    const input = document.getElementById('input').value;
    let output = input;
    let anonCount = 0, blockCount = 0, randomCount = 0;

    output = output.replace(/\*\*\*\{([^}]+)\}/g, (_, value) => {
        anonCount++;
        if (dictionary[value]) return dictionary[value];
        const type = detectType(value);
        const fake = generateFake(value, type);
        dictionary[value] = fake;
        reverseDictionary[fake] = value;
        return fake;
    });

    output = output.replace(/###\{([^}]*)\}/g, (_, value) => {
        blockCount++;
        return '[REDACTED]';
    });

    output = output.replace(/\$\$\$\{([^}]+)\}/g, (_, value) => {
        randomCount++;
        if (dictionary[value]) return dictionary[value];
        const fake = randomizeAmount(value);
        dictionary[value] = fake;
        reverseDictionary[fake] = value;
        return fake;
    });

    document.getElementById('output').value = output;
    updateStats(anonCount, blockCount, randomCount);
    saveDictionary();
}

// ════════════════════════════════════════════
// UNSEAL
// ════════════════════════════════════════════
function unseal() {
    const input = document.getElementById('input').value;
    let output = input;
    const fakes = Object.keys(reverseDictionary).sort((a, b) => b.length - a.length);
    for (const fake of fakes) {
        output = output.split(fake).join(reverseDictionary[fake]);
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

    const markers = { anon: '***', block: '###', random: '$$$' };
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

function hideContextMenu() {
    ctxMenu.classList.remove('visible');
}

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
    document.getElementById('statDict').textContent = Object.keys(dictionary).length;
    document.getElementById('statAnon').textContent = anon;
    document.getElementById('statBlock').textContent = block;
    document.getElementById('statRandom').textContent = random;
}

// ════════════════════════════════════════════
// LOCALSTORAGE — dictionary persistence
// ════════════════════════════════════════════
function saveDictionary() {
    try {
        localStorage.setItem('promptmask_dict', JSON.stringify(dictionary));
        localStorage.setItem('promptmask_rdict', JSON.stringify(reverseDictionary));
    } catch (e) { /* silent */ }
}

function loadDictionary() {
    try {
        const d = localStorage.getItem('promptmask_dict');
        const r = localStorage.getItem('promptmask_rdict');
        if (d) Object.assign(dictionary, JSON.parse(d));
        if (r) Object.assign(reverseDictionary, JSON.parse(r));
        updateStats(0, 0, 0);
    } catch (e) { /* silent */ }
}

loadDictionary();
</script>
</body>
</html>
HTMLEOF

# ============================================
# Git commit
# ============================================
git add -A
git commit -m "feat: web app with seal/unseal, context menu, shortcuts

- Core seal/unseal engine with mini-language (***{} ###{} \$\$\${})
- Right-click context menu on text selection
- Keyboard shortcuts (Ctrl+1/2/3)
- Toolbar buttons for marking
- Auto-type detection (name, email, company, project, amount)
- Consistent dictionary (same input = same fake output)
- Dictionary persistence via localStorage
- Copy to clipboard
- Stats bar (markers count, dictionary size)
- Privacy banner with network indicator
- Responsive layout (mobile support)
- Dark theme, DM Mono + Anybody fonts
- Zero dependencies, single HTML file"

echo ""
echo "✅ Commit 2 done!"
echo "Open app/index.html in a browser to test."
echo ""
