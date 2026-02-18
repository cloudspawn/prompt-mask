#!/bin/bash
cd ~/projets/prompt-mask

python3 << 'PYEOF'
with open('README.md', 'r') as f:
    content = f.read()

old_cli = '''## CLI (coming soon)

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

The CLI will share the same dictionary format as the web app (JSON), so you can export from one and import in the other.'''

new_cli = '''## CLI

A Python CLI for developers. Zero dependencies, pure Python 3.8+.

### Install

```bash
pip install prompt-mask
# or from source
git clone https://github.com/cloudspawn/prompt-mask.git && cd prompt-mask
pip install -e .
```

### Example session

```
$ prompt-mask scan "Jean Dupont (CEO, Nexus Tech) called Marie Laurent.
  Jean Dupont wants to close the 450k deal by 15/03/2025.
  Contact: jdupont@nexus-tech.com
  Jean Dupont and Marie Laurent will sign next week."

Scanning...

  Emails:
    jdupont@nexus-tech.com  (1x)  ->  [a]nonymize [b]lock [r]andomize [s]kip ? a

  Dates:
    15/03/2025  (1x)  ->  [a]nonymize [b]lock [r]andomize [s]kip ? r

  Amounts:
    450k  (1x)  ->  [a]nonymize [b]lock [r]andomize [s]kip ? r

  Names:
    Jean Dupont    (3x)  ->  [a]nonymize [b]lock [r]andomize [s]kip ? a
    Marie Laurent  (2x)  ->  [a]nonymize [b]lock [r]andomize [s]kip ? a
    Nexus Tech     (1x)  ->  [a]nonymize [b]lock [r]andomize [s]kip ? a

Apply 7 changes? [y/N] y
Alex Morgan (CEO, Vertex Labs) called Sam Rivera.
Alex Morgan wants to close the 382k deal by 28/02/2025.
Contact: contact@vertex-labs.com
Alex Morgan and Sam Rivera will sign next week.

Sealed: 10 new + 0 from dictionary.
```

Next time, the dictionary already knows these names -- use `auto`:

```
$ prompt-mask auto "Reminder: Jean Dupont from Nexus Tech meets Marie Laurent on Friday."

Known entries found:
  Jean Dupont   -> Alex Morgan   (1x, name)
  Marie Laurent -> Sam Rivera    (1x, name)
  Nexus Tech    -> Vertex Labs   (1x, company)

Apply all replacements? [y/N] y
Reminder: Alex Morgan from Vertex Labs meets Sam Rivera on Friday.
Auto-sealed: 3 replacements from dictionary.
```

### Commands

**Seal** -- process markers in text:
```bash
prompt-mask seal "Send invoice to ***{Jean Dupont} at ***{Nexus Tech}"
prompt-mask seal spec.md -o spec-safe.md
cat file.md | prompt-mask seal > safe.md
```

**Unseal** -- restore real data:
```bash
prompt-mask unseal "Send invoice to Alex Morgan at Vertex Labs"
prompt-mask unseal response.md -o final.md
```

**Auto** -- seal using existing dictionary (no markers needed):
```bash
prompt-mask auto spec.md -o spec-safe.md
prompt-mask auto spec.md -o spec-safe.md -y  # skip confirmation
```

**Scan** -- interactive detection of sensitive data:
```bash
prompt-mask scan spec.md -o spec-safe.md
```
Detects names, emails, IPs, phone numbers, dates, amounts, URLs, and API keys/tokens.
For each finding, choose: `[a]nonymize [b]lock [r]andomize [s]kip`.

**Projects:**
```bash
prompt-mask project list
prompt-mask project create client-x
prompt-mask project use client-x
prompt-mask project delete client-x
```

**Dictionary:**
```bash
prompt-mask dict list
prompt-mask dict add --real "Secret Corp" --fake "Public Inc"
prompt-mask dict remove --real "Secret Corp"
prompt-mask dict export -o backup.json
prompt-mask dict import -i backup.json
prompt-mask dict clear
```

Dictionary format is identical to the web app -- export from one, import in the other.'''

if old_cli in content:
    content = content.replace(old_cli, new_cli)
    print("Replaced CLI section")
else:
    print("ERROR: Could not find old CLI section")
    # Debug: show what's around "## CLI"
    idx = content.find('## CLI')
    if idx >= 0:
        print(f"Found '## CLI' at position {idx}")
        print(repr(content[idx:idx+100]))

with open('README.md', 'w') as f:
    f.write(content)
PYEOF

git add -A
git commit --amend --no-edit
git push origin dev --force

echo ""
echo "Done"
