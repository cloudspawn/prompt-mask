#!/bin/bash
# ============================================
# COMMIT 5: Prompt history with search, export
# ============================================
# Run from inside prompt-mask/
# This patches the existing index.html to add history

cd app

python3 << 'PYEOF'
with open('index.html', 'r') as f:
    content = f.read()

# ═══════════════════════════════════════
# 1. Add CSS for history panel
# ═══════════════════════════════════════
history_css = """
        /* ── History panel ── */
        .history-panel {
            border-top: 1px solid var(--border);
            max-height: 0; overflow: hidden;
            transition: max-height 0.3s ease;
        }
        .history-panel.open { max-height: 800px; overflow-y: auto; }
        .history-header {
            display: flex; align-items: center; justify-content: space-between;
            padding: 12px 40px; position: sticky; top: 0;
            background: var(--bg); z-index: 1;
        }
        .history-header .history-title {
            font-family: 'Anybody', sans-serif; font-weight: 600;
            font-size: 11px; text-transform: uppercase;
            letter-spacing: 1.5px; color: var(--text-muted);
        }
        .history-actions { display: flex; gap: 6px; align-items: center; }
        .history-search {
            font-family: 'DM Mono', monospace; font-size: 12px;
            padding: 5px 10px; background: var(--surface);
            color: var(--text); border: 1px solid var(--border);
            border-radius: var(--radius); outline: none; width: 200px;
        }
        .history-search:focus { border-color: var(--accent-dim); }
        .history-search::placeholder { color: var(--text-muted); }
        .history-list { padding: 0 40px 16px; }
        .history-item {
            border: 1px solid var(--border); border-radius: var(--radius);
            margin-bottom: 8px; overflow: hidden;
            transition: border-color 0.15s;
        }
        .history-item:hover { border-color: var(--accent-dim); }
        .history-item-header {
            display: flex; align-items: center; justify-content: space-between;
            padding: 8px 12px; background: var(--surface);
            cursor: pointer; gap: 12px;
        }
        .history-item-header:hover { background: var(--surface-hover); }
        .history-meta {
            display: flex; align-items: center; gap: 12px;
            font-size: 11px; color: var(--text-muted); flex: 1;
        }
        .history-meta .history-date { color: var(--text); font-weight: 500; }
        .history-meta .history-project {
            font-size: 9px; padding: 2px 6px;
            border-radius: 4px; background: rgba(245,158,11,0.12);
            color: var(--anon); text-transform: uppercase; letter-spacing: 0.5px;
        }
        .history-meta .history-preview {
            flex: 1; overflow: hidden; text-overflow: ellipsis;
            white-space: nowrap; color: var(--text-muted);
        }
        .history-item-actions { display: flex; gap: 4px; }
        .history-item-actions button {
            background: none; border: none; color: var(--text-muted);
            cursor: pointer; padding: 2px 6px; font-size: 12px;
            border-radius: 4px;
        }
        .history-item-actions button:hover { color: var(--text); background: var(--surface-hover); }
        .history-item-actions button.del:hover { color: var(--block); background: rgba(239,68,68,0.1); }
        .history-item-body {
            display: none; padding: 12px;
            border-top: 1px solid var(--border);
        }
        .history-item-body.open { display: block; }
        .history-item-body .history-label {
            font-size: 9px; text-transform: uppercase;
            letter-spacing: 1px; color: var(--text-muted);
            margin-bottom: 4px;
        }
        .history-item-body pre {
            font-family: 'DM Mono', monospace; font-size: 11px;
            line-height: 1.6; color: var(--text);
            background: var(--surface); padding: 10px;
            border-radius: var(--radius); white-space: pre-wrap;
            word-break: break-word; margin-bottom: 10px;
            max-height: 150px; overflow-y: auto;
        }
        .history-stats-row {
            display: flex; gap: 12px; font-size: 10px;
            color: var(--text-muted); margin-top: 6px;
        }
        .history-empty {
            text-align: center; padding: 24px 40px;
            color: var(--text-muted); font-size: 12px; font-style: italic;
        }
"""

# Insert CSS before the responsive media query
content = content.replace(
    "        /* ── Responsive ── */",
    history_css + "\n        /* ── Responsive ── */"
)

# Add responsive rules for history
content = content.replace(
    "header { flex-direction: column; align-items: flex-start; gap: 12px; }",
    "header { flex-direction: column; align-items: flex-start; gap: 12px; }\n            .history-header, .history-list { padding-left: 20px; padding-right: 20px; }"
)

# ═══════════════════════════════════════
# 2. Add History panel HTML after dict panel
# ═══════════════════════════════════════
history_html = """
<!-- History panel -->
<div class="history-panel" id="historyPanel">
    <div class="history-header">
        <span class="history-title">📋 Prompt History — <span id="historyCount">0</span> entries</span>
        <div class="history-actions">
            <input type="text" class="history-search" id="historySearch" placeholder="Search prompts..." oninput="renderHistory()">
            <button onclick="exportHistory()">Export</button>
            <button class="danger" onclick="clearHistory()">Clear all</button>
        </div>
    </div>
    <div class="history-list" id="historyList"></div>
</div>
"""

content = content.replace(
    "<!-- Context menu -->",
    history_html + "\n<!-- Context menu -->"
)

# ═══════════════════════════════════════
# 3. Add History toggle button in stats bar
# ═══════════════════════════════════════
content = content.replace(
    '<button onclick="toggleDict()" id="dictToggleBtn">📖 Dictionary</button>',
    '<button onclick="toggleDict()" id="dictToggleBtn">📖 Dictionary</button>\n        <button onclick="toggleHistory()" id="historyToggleBtn" style="margin-left:4px">📋 History</button>'
)

# ═══════════════════════════════════════
# 4. Add History JS before loadAll()
# ═══════════════════════════════════════
history_js = """
// ════════════════════════════════════════════
// PROMPT HISTORY
// ════════════════════════════════════════════
let history = [];

function savePromptToHistory(original, sealed, anonCount, blockCount, randomCount) {
    const entry = {
        id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
        timestamp: new Date().toISOString(),
        project: currentProject,
        original: original,
        sealed: sealed,
        stats: { anon: anonCount, block: blockCount, random: randomCount },
    };
    history.unshift(entry);
    if (history.length > 500) history = history.slice(0, 500);
    saveHistory();
    renderHistory();
}

function toggleHistory() {
    const panel = document.getElementById('historyPanel');
    panel.classList.toggle('open');
    // Close dict if open
    if (panel.classList.contains('open')) {
        document.getElementById('dictPanel').classList.remove('open');
    }
    renderHistory();
}

function renderHistory() {
    const container = document.getElementById('historyList');
    const search = (document.getElementById('historySearch').value || '').toLowerCase();

    let filtered = history;
    if (search) {
        filtered = history.filter(h =>
            h.original.toLowerCase().includes(search) ||
            h.sealed.toLowerCase().includes(search) ||
            h.project.toLowerCase().includes(search)
        );
    }

    document.getElementById('historyCount').textContent = history.length;

    if (filtered.length === 0) {
        container.innerHTML = '<div class="history-empty">' +
            (history.length === 0 ? 'No prompts yet. History is saved automatically when you seal.' : 'No prompts match your search.') +
            '</div>';
        return;
    }

    let html = '';
    for (const entry of filtered) {
        const date = new Date(entry.timestamp);
        const dateStr = date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'});
        const preview = entry.original.replace(/[\\*\\-\\+]{3}\\{([^}]*)\\}/g, '$1').slice(0, 80);
        const totalMarkers = entry.stats.anon + entry.stats.block + entry.stats.random;

        html += '<div class="history-item">' +
            '<div class="history-item-header" onclick="toggleHistoryItem(\\'' + entry.id + '\\')">' +
            '<div class="history-meta">' +
            '<span class="history-date">' + dateStr + '</span>' +
            '<span class="history-project">' + escHtml(entry.project) + '</span>' +
            '<span class="history-preview">' + escHtml(preview) + (entry.original.length > 80 ? '...' : '') + '</span>' +
            '</div>' +
            '<div class="history-item-actions">' +
            '<button onclick="event.stopPropagation();reusePrompt(\\''+entry.id+'\\');" title="Reuse in editor">↩</button>' +
            '<button class="del" onclick="event.stopPropagation();deleteHistoryItem(\\''+entry.id+'\\');" title="Delete">×</button>' +
            '</div>' +
            '</div>' +
            '<div class="history-item-body" id="hist-' + entry.id + '">' +
            '<div class="history-label">Original prompt</div>' +
            '<pre>' + escHtml(entry.original) + '</pre>' +
            '<div class="history-label">Sealed output</div>' +
            '<pre>' + escHtml(entry.sealed) + '</pre>' +
            '<div class="history-stats-row">' +
            '<span>Anonymized: ' + entry.stats.anon + '</span>' +
            '<span>Blocked: ' + entry.stats.block + '</span>' +
            '<span>Randomized: ' + entry.stats.random + '</span>' +
            '<span>Total markers: ' + totalMarkers + '</span>' +
            '</div>' +
            '</div>' +
            '</div>';
    }
    container.innerHTML = html;
}

function toggleHistoryItem(id) {
    const body = document.getElementById('hist-' + id);
    if (body) body.classList.toggle('open');
}

function reusePrompt(id) {
    const entry = history.find(h => h.id === id);
    if (!entry) return;
    setMode('seal');
    document.getElementById('input').value = entry.original;
}

function deleteHistoryItem(id) {
    history = history.filter(h => h.id !== id);
    saveHistory();
    renderHistory();
}

function clearHistory() {
    if (!confirm('Delete all prompt history?')) return;
    history = [];
    saveHistory();
    renderHistory();
}

function exportHistory() {
    const data = {
        version: 1,
        exported: new Date().toISOString(),
        count: history.length,
        prompts: history
    };
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'prompt-mask_history_' + new Date().toISOString().slice(0,10) + '.json';
    a.click();
    URL.revokeObjectURL(url);
}

function saveHistory() {
    try {
        localStorage.setItem('promptmask_history', JSON.stringify(history));
    } catch (e) { /* silent */ }
}

function loadHistory() {
    try {
        const h = localStorage.getItem('promptmask_history');
        if (h) history = JSON.parse(h);
    } catch (e) { /* silent */ }
}
"""

content = content.replace(
    "// ════════════════════════════════════════════\n// PERSISTENCE",
    history_js + "\n// ════════════════════════════════════════════\n// PERSISTENCE"
)

# ═══════════════════════════════════════
# 5. Hook seal() to save history
# ═══════════════════════════════════════
content = content.replace(
    "    document.getElementById('output').value = output;\n    updateStats(anonCount, blockCount, randomCount);\n    saveAll();\n    renderDict();",
    "    document.getElementById('output').value = output;\n    updateStats(anonCount, blockCount, randomCount);\n    savePromptToHistory(input, output, anonCount, blockCount, randomCount);\n    saveAll();\n    renderDict();"
)

# ═══════════════════════════════════════
# 6. Add loadHistory() to loadAll()
# ═══════════════════════════════════════
content = content.replace(
    "    if (!projects['default']) initProject('default');\n    renderProjectSelect(); renderDict(); updateStats(0, 0, 0);",
    "    if (!projects['default']) initProject('default');\n    loadHistory();\n    renderProjectSelect(); renderDict(); updateStats(0, 0, 0);"
)

# ═══════════════════════════════════════
# 7. Also close history when opening dict
# ═══════════════════════════════════════
content = content.replace(
    "function toggleDict() {\n    document.getElementById('dictPanel').classList.toggle('open');\n    renderDict();\n}",
    "function toggleDict() {\n    document.getElementById('dictPanel').classList.toggle('open');\n    if (document.getElementById('dictPanel').classList.contains('open')) {\n        document.getElementById('historyPanel').classList.remove('open');\n    }\n    renderDict();\n}"
)

with open('index.html', 'w') as f:
    f.write(content)

print("Patched index.html with history")
PYEOF

cd ..

# ============================================
# Git commit
# ============================================
git add -A
git commit -m "feat: prompt history with search, reuse, export

- Every seal auto-saves to history (max 500 entries)
- History panel (toggle with 📋 button)
  - Expandable entries showing original + sealed prompt
  - Stats per entry (anon/block/random counts)
  - Search across all prompts
  - Reuse button (↩) loads prompt back into editor
  - Delete individual entries
  - Clear all history
- Export full history as JSON
- Dict and history panels are mutually exclusive
- History persisted in localStorage"

echo ""
echo "✅ Commit 5 done!"
echo "Refresh app/index.html to test."
echo ""
