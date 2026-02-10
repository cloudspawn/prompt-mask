# 🎭 prompt-mask

**Anonymize your prompts before sending them to AI. 100% local. Zero data leaves your device.**

prompt-mask sits between you and the AI — you mask sensitive data before sending, and unmask the response when it comes back. Names, emails, amounts, secrets: the AI never sees the real thing.

No server. No account. No tracking. Just open the page and go.

## How it works

```
You type:    "Draft an email to ***{Jean Dupont} at ***{Nexus Tech} about +++{450k€}"
prompt-mask: "Draft an email to Alex Morgan at Vertex Labs about 518k€"
AI responds: "Dear Alex Morgan from Vertex Labs..."
prompt-mask: "Dear Jean Dupont from Nexus Tech..."
```

## Quick Start

### Web App (recommended — no install)

**Use it now:** [cloudspawn.github.io/prompt-mask](https://cloudspawn.github.io/prompt-mask)

Or download `app/index.html` and open it locally. Works offline, works everywhere.

### How to use

1. **SEAL mode** — Write your prompt, mark sensitive data, hit SEAL, copy the masked output to your AI tool
2. **UNSEAL mode** — Paste the AI response, hit UNSEAL, get the real data back

Three ways to mark sensitive data:

| Method | How |
|--------|-----|
| **Type markers** | `***{Jean Dupont}` directly in the text |
| **Right-click** | Select text → right-click → choose action |
| **Keyboard** | Select text → Ctrl+1, Ctrl+2, or Ctrl+3 |

### Mini-Language

| Marker | Action | Reversible? | Example |
|--------|--------|-------------|---------|
| `***{text}` | **Anonymize** — realistic fake replacement | ✅ Yes | `***{Jean Dupont}` → `Alex Morgan` |
| `+++{text}` | **Randomize** — same type, different value | ✅ Yes | `+++{450k€}` → `518k€` |
| `---{text}` | **Block** — permanently redact | ❌ No | `---{password}` → `[REDACTED:1]` |

Use `***` and `+++` when you need the AI to work with realistic data and want to restore it later. Use `---` for secrets that should never be stored anywhere.

## Features

- **Seal / Unseal** — mask before sending, unmask after receiving
- **Auto-dictionary** — consistent mappings that build up over time
- **Projects** — separate dictionaries per client/project/context
- **Prompt history** — automatic log of everything you've sealed, searchable, exportable
- **Mini audit** — stats on what you've protected
- **Export / Import** — backup and share your dictionaries and history
- **Context menu & shortcuts** — right-click or Ctrl+1/2/3 for fast marking

## 🔒 Privacy by Design

This is NOT a web app that sends your data somewhere. It's a single HTML file that runs entirely in your browser.

- ❌ No server — nothing is hosted, processed, or stored remotely
- ❌ No database — your data lives in your browser's localStorage only
- ❌ No account — no signup, no login, no email
- ❌ No tracking — no analytics, no cookies, no telemetry
- ❌ No network requests — ever, under any circumstance
- ✅ Works fully offline — download the file, disconnect your WiFi
- ✅ Open source — read every line of code yourself

### How to verify

1. Open DevTools (F12)
2. Go to the Network tab
3. Use the app
4. See for yourself: zero network requests

## CLI (coming soon)

A Python CLI for developers who want to integrate prompt-mask into their workflow — piping, scripting, pre-commit hooks, and more.

```bash
pip install prompt-mask

# Seal a prompt
prompt-mask seal "Send the invoice to ***{Jean Dupont}"

# Seal a file
prompt-mask seal < spec.md > spec-safe.md

# Unseal AI response
prompt-mask unseal < ai-response.md > final.md
```

The CLI will share the same dictionary format as the web app (JSON), so you can export from one and import in the other.

## Roadmap

- [x] Web app — core seal/unseal with mini-language
- [x] Right-click context menu & keyboard shortcuts
- [x] Consistent auto-dictionary (localStorage)
- [x] Project/context system
- [x] Dictionary manager (view, add, delete, export, import)
- [x] Seal/unseal mode with clear UX guidance
- [x] Prompt history (auto-save, search, reuse, export)
- [x] Numbered redaction (non-reversible, nothing stored)
- [x] Mini audit & stats
- [x] GitHub Pages deployment
- [ ] CLI — Python package for terminal workflows
- [ ] Browser extension (future)

## Development

```bash
git clone https://github.com/cloudspawn/prompt-mask.git
cd prompt-mask
uv sync

# Serve the web app locally
cd app && python3 -m http.server 8080
```

## Contributing

Contributions welcome! Please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
