#!/bin/bash
cd ~/projets/prompt-mask

# ═══════════════════════════════════════
# 1. Add to README
# ═══════════════════════════════════════
python3 << 'PYEOF'
with open('README.md', 'r') as f:
    content = f.read()

# Add support badge after title
content = content.replace(
    '# 🎭 prompt-mask',
    '''# 🎭 prompt-mask

<a href="https://buymeacoffee.com/promptmask" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="40"></a>'''
)

# Add support section before Contributing
content = content.replace(
    '## Contributing',
    '''## Support

prompt-mask is free, open source, and always will be. If it saves you time or protects your data, consider buying me a coffee:

<a href="https://buymeacoffee.com/promptmask" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50"></a>

## Contributing'''
)

with open('README.md', 'w') as f:
    f.write(content)
print("README updated")
PYEOF

# ═══════════════════════════════════════
# 2. Add to web app (footer link)
# ═══════════════════════════════════════
python3 << 'PYEOF'
with open('app/index.html', 'r') as f:
    content = f.read()

# Add a subtle link in the privacy banner
content = content.replace(
    '<span style="margin-left:4px; opacity:0.5">Press F12',
    '<a href="https://buymeacoffee.com/promptmask" target="_blank" style="margin-left:12px; color:var(--accent); text-decoration:none; opacity:0.7">☕ Support this project</a><span style="margin-left:4px; opacity:0.5">Press F12'
)

with open('app/index.html', 'w') as f:
    f.write(content)
print("Web app updated")
PYEOF

# ═══════════════════════════════════════
# 3. Commit
# ═══════════════════════════════════════
git add -A
git commit -m "chore: add Buy Me a Coffee links to README and web app

- Badge in README header
- Support section in README
- Subtle link in web app privacy banner"

echo ""
echo "Done! Push and PR when ready."
