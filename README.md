# 🎭 prompt-mask

**Anonymize your prompts before sending them to AI. 100% local. Zero data leaves your device.**

prompt-mask is a lightweight tool that lets you mask sensitive data (names, emails, amounts, secrets) in your prompts before pasting them into ChatGPT, Claude, or any AI tool — and unmask the AI's response afterward.

No server. No account. No tracking. Just open the HTML file and go.

## Why?

Every day, millions of people paste client names, emails, financial data, and internal information into AI chatbots without thinking twice. That data hits external servers and you lose control over it.

prompt-mask sits between you and the AI:

```
You type:    "Draft an email to ***{Jean Dupont} at ***{Nexus Tech} about +++{450k€}"
prompt-mask: "Draft an email to Marc Lefèvre at Alpha Corp about 382k€"
AI responds: "Dear Marc Lefèvre from Alpha Corp..."
prompt-mask: "Dear Jean Dupont from Nexus Tech..."
```

You stay in control. The AI never sees the real data.

## Quick Start

### Web App (no install needed)

1. Open `app/index.html` in your browser — or visit [cloudspawn.github.io/prompt-mask](https://cloudspawn.github.io/prompt-mask)
2. Paste your text
3. Mark sensitive data with `***{...}`
4. Copy the masked version to your AI tool
5. Paste the AI response back to unmask

### CLI (for developers)

```bash
pip install prompt-mask
```

```bash
# Mask a prompt
prompt-mask seal "Send the invoice to ***{Jean Dupont} at ***{Nexus Tech}"

# Unmask AI response
prompt-mask unseal "I've prepared the invoice for Marc Lefèvre at Alpha Corp"
```

## Mini-Language

Three markers, that's all you need:

| Marker | Meaning | Example | Result |
|--------|---------|---------|--------|
| `***{text}` | **Anonymize** — replace with realistic fake | `***{Jean Dupont}` | `Marc Lefèvre` |
| `---{text}` | **Block** — redact completely | `---{secret}` | `[REDACTED]` |
| `+++{text}` | **Randomize** — same type, different value | `+++{450k€}` | `382k€` |

The same real value always maps to the same fake value across all your prompts (consistent dictionary).

## 🔒 Privacy by Design

This is NOT a web app that sends your data somewhere. It's a single HTML file that runs entirely in your browser.

- ❌ No server
- ❌ No database
- ❌ No user account
- ❌ No cookies or tracking
- ❌ No network requests — ever
- ✅ Works offline (download the HTML file)
- ✅ Your data stays in your browser (localStorage)
- ✅ Code is open source and auditable

### How to verify

1. Open DevTools (F12)
2. Go to the Network tab
3. Use the app
4. See for yourself: zero network requests

## Features

- **Seal / Unseal** — mask before sending, unmask after receiving
- **Auto-dictionary** — builds up over time, remembers your mappings
- **Prompt history** — local log of everything you've sent to AI tools
- **Mini audit** — stats on what you've protected (and what you haven't)
- **Privacy score** — see how well you're protecting your data
- **Post-send check** — optional safety net that catches unmarked sensitive data

## Roadmap

- [x] Project setup
- [ ] Web app — core seal/unseal with mini-language
- [ ] Web app — persistent dictionary
- [ ] Web app — prompt history
- [ ] Web app — audit & stats
- [ ] CLI — Python package with same features
- [ ] Browser extension (future)

## Development

```bash
# Clone
git clone https://github.com/cloudspawn/prompt-mask.git
cd prompt-mask

# Setup with uv
uv sync

# Run CLI (once implemented)
uv run prompt-mask seal "your prompt here"

# Run tests
uv run pytest
```

## Contributing

Contributions welcome! Please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
