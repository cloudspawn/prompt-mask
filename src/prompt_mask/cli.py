"""Command line interface for prompt-mask."""

import sys
import json
import argparse
from pathlib import Path
from . import __version__
from . import engine, storage, detector


# ── Colors for terminal output ──
class C:
    AMBER = "\033[33m"
    RED = "\033[31m"
    PURPLE = "\033[35m"
    GREEN = "\033[32m"
    CYAN = "\033[36m"
    DIM = "\033[2m"
    BOLD = "\033[1m"
    RESET = "\033[0m"


def read_input(source):
    """Read from file path, string argument, or stdin."""
    if source and len(source) < 260 and Path(source).is_file():
        return Path(source).read_text(encoding="utf-8")
    if source:
        return source
    if not sys.stdin.isatty():
        return sys.stdin.read()
    print("Error: provide text, a file path, or pipe via stdin.", file=sys.stderr)
    sys.exit(1)


def write_output(text, output_path=None):
    """Write to file or stdout."""
    if output_path:
        Path(output_path).write_text(text, encoding="utf-8")
        print(f"Written to {output_path}", file=sys.stderr)
    else:
        print(text)


# ════════════════════════════════════════
# Seal / Unseal
# ════════════════════════════════════════

def cmd_seal(args):
    text = read_input(args.input)
    result, stats = engine.seal(text, project=args.project)
    write_output(result, args.output)
    total = stats["anon"] + stats["block"] + stats["random"]
    if total > 0:
        print(
            f"Sealed: {stats['anon']} anonymized, {stats['block']} blocked, "
            f"{stats['random']} randomized ({total} total)",
            file=sys.stderr,
        )


def cmd_unseal(args):
    text = read_input(args.input)
    result = engine.unseal(text, project=args.project)
    write_output(result, args.output)
    print("Unsealed.", file=sys.stderr)


# ════════════════════════════════════════
# Auto
# ════════════════════════════════════════

def cmd_auto(args):
    text = read_input(args.input)
    data = storage.load_dict(args.project)
    d = data["dict"]

    if not d:
        print("Dictionary is empty. Use 'scan' or 'dict add' first.", file=sys.stderr)
        sys.exit(1)

    # Show what will be replaced
    found = detector.find_known_in_text(text, d)
    if not found:
        print("No known dictionary entries found in text.", file=sys.stderr)
        write_output(text, args.output)
        return

    if not args.yes:
        print(f"\n{C.BOLD}Known entries found:{C.RESET}\n", file=sys.stderr)
        for real, fake, count in found:
            t = data["types"].get(real, "?")
            print(
                f"  {C.AMBER}{real}{C.RESET} → {C.GREEN}{fake}{C.RESET}"
                f"  {C.DIM}({count}x, {t}){C.RESET}",
                file=sys.stderr,
            )
        print(file=sys.stderr)
        confirm = input("Apply all replacements? [y/N] ")
        if confirm.lower() != "y":
            print("Cancelled.")
            return

    result, count = engine.auto_seal(text, project=args.project)
    write_output(result, args.output)
    print(f"Auto-sealed: {count} replacements from dictionary.", file=sys.stderr)


# ════════════════════════════════════════
# Scan
# ════════════════════════════════════════

def cmd_scan(args):
    text = read_input(args.input)
    project = args.project
    data = storage.load_dict(project)
    d = data["dict"]

    print(f"\n{C.BOLD}Scanning...{C.RESET}\n", file=sys.stderr)

    # 1. Check known dictionary entries first
    known = detector.find_known_in_text(text, d)
    if known:
        print(f"  {C.GREEN}{C.BOLD}Known from dictionary:{C.RESET}", file=sys.stderr)
        for real, fake, count in known:
            t = data["types"].get(real, "?")
            print(
                f"    {C.AMBER}{real}{C.RESET} → {C.GREEN}{fake}{C.RESET}"
                f"  {C.DIM}({count}x, {t}){C.RESET} ✓",
                file=sys.stderr,
            )
        print(file=sys.stderr)

    # 2. Detect new sensitive data
    findings = detector.detect_all(text)

    # Remove already-known entries from findings
    for category, items in list(findings.items()):
        findings[category] = [(v, c) for v, c in items if v not in d]
        if not findings[category]:
            del findings[category]

    if not findings and not known:
        print("  Nothing detected.", file=sys.stderr)
        return

    # 3. Interactive: ask user what to do with each finding
    actions = {}  # value → (action, type)
    type_labels = {
        "name": f"{C.AMBER}Names",
        "email": f"{C.RED}Emails",
        "ip": f"{C.RED}IPs",
        "phone": f"{C.RED}Phone numbers",
        "date": f"{C.PURPLE}Dates",
        "amount": f"{C.PURPLE}Amounts",
        "url": f"{C.CYAN}URLs",
        "token": f"{C.RED}API keys / tokens",
    }

    for category, items in findings.items():
        label = type_labels.get(category, category)
        print(f"  {C.BOLD}{label}:{C.RESET}", file=sys.stderr)
        for value, count in items:
            prompt_str = (
                f"    {C.AMBER}{value}{C.RESET}"
                f"  {C.DIM}({count}x){C.RESET}"
                f"  →  [a]nonymize [b]lock [r]andomize [s]kip ? "
            )
            while True:
                choice = input(prompt_str).strip().lower()
                if choice in ("a", "b", "r", "s", ""):
                    break
                print("    Invalid choice. Use a/b/r/s.", file=sys.stderr)

            if choice == "s" or choice == "":
                continue
            actions[value] = (choice, category)
        print(file=sys.stderr)

    if not actions and not known:
        print("No actions selected.", file=sys.stderr)
        return

    # 4. Apply
    total_actions = len(actions) + len(known)
    if total_actions == 0:
        return

    confirm = input(f"Apply {total_actions} changes? [y/N] ")
    if confirm.lower() != "y":
        print("Cancelled.")
        return

    result = text

    # Apply known dictionary entries first
    for real, fake, count in known:
        result = result.replace(real, fake)

    # Apply new actions
    sealed_count = 0
    block_counter = 0
    block_counter = 0
    for value, (action, category) in actions.items():
        if action == "a":
            t = engine.detect_type(value) if category == "name" else category
            fake = engine.generate_fake(value, t)
            storage.add_mapping(value, fake, t, project)
            result = result.replace(value, fake)
            sealed_count += result.count(fake) if result.count(fake) > 0 else 1
        elif action == "b":
            while value in result:
                block_counter += 1
                result = result.replace(value, f"[REDACTED:{block_counter}]", 1)
                sealed_count += 1
        elif action == "r":
            fake = engine.randomize_value(value)
            t = category if category in ("date", "amount") else "text"
            storage.add_mapping(value, fake, t, project)
            result = result.replace(value, fake)
            sealed_count += 1

    write_output(result, args.output)
    print(f"\nSealed: {sealed_count} new + {len(known)} from dictionary.", file=sys.stderr)


# ════════════════════════════════════════
# Project commands
# ════════════════════════════════════════

def cmd_project(args):
    action = args.action

    if action == "list":
        current = storage.get_current_project()
        projects = storage.list_projects()
        if not projects:
            print("No projects yet.")
            return
        for p in projects:
            marker = "→ " if p == current else "  "
            data = storage.load_dict(p)
            count = len(data["dict"])
            print(f"{marker}{p} ({count} entries)")

    elif action == "use":
        if not args.name:
            print("Error: provide a project name.", file=sys.stderr)
            sys.exit(1)
        storage.set_current_project(args.name)
        storage.get_project_dir(args.name)
        print(f"Switched to project: {args.name}")

    elif action == "create":
        if not args.name:
            print("Error: provide a project name.", file=sys.stderr)
            sys.exit(1)
        storage.get_project_dir(args.name)
        storage.set_current_project(args.name)
        print(f"Created and switched to project: {args.name}")

    elif action == "delete":
        if not args.name:
            print("Error: provide a project name.", file=sys.stderr)
            sys.exit(1)
        try:
            storage.delete_project(args.name)
            print(f"Deleted project: {args.name}")
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

    else:
        print("Usage: prompt-mask project [list|use|create|delete] [name]")


# ════════════════════════════════════════
# Dict commands
# ════════════════════════════════════════

def cmd_dict(args):
    action = args.action
    project = args.project

    if action == "list":
        data = storage.load_dict(project)
        entries = data["dict"]
        types = data["types"]
        if not entries:
            print("Dictionary is empty.")
            return
        max_real = max(len(r) for r in entries)
        max_fake = max(len(f) for f in entries.values())
        max_real = max(max_real, 4)
        max_fake = max(max_fake, 6)
        print(f"{'REAL':<{max_real}}  {'MASKED':<{max_fake}}  TYPE")
        print(f"{'─' * max_real}  {'─' * max_fake}  {'─' * 10}")
        for real, fake in entries.items():
            t = types.get(real, "identity")
            print(f"{real:<{max_real}}  {fake:<{max_fake}}  {t}")
        print(f"\n{len(entries)} entries")

    elif action == "add":
        if not args.real or not args.fake:
            print("Error: provide --real and --fake values.", file=sys.stderr)
            sys.exit(1)
        t = args.type or engine.detect_type(args.real)
        storage.add_mapping(args.real, args.fake, t, project)
        print(f"Added: {args.real} → {args.fake} ({t})")

    elif action == "remove":
        if not args.real:
            print("Error: provide --real value to remove.", file=sys.stderr)
            sys.exit(1)
        storage.remove_mapping(args.real, project)
        print(f"Removed: {args.real}")

    elif action == "export":
        data = storage.export_dict(project)
        output = json.dumps(data, indent=2, ensure_ascii=False)
        if args.output:
            Path(args.output).write_text(output, encoding="utf-8")
            print(f"Exported {len(data['entries'])} entries to {args.output}", file=sys.stderr)
        else:
            print(output)

    elif action == "import":
        if not args.input:
            print("Error: provide a JSON file to import.", file=sys.stderr)
            sys.exit(1)
        path = Path(args.input)
        if not path.is_file():
            print(f"Error: file not found: {args.input}", file=sys.stderr)
            sys.exit(1)
        raw = json.loads(path.read_text(encoding="utf-8"))
        entries = raw.get("entries", [])
        target = raw.get("project", project) if not project else project
        storage.get_project_dir(target)
        count = storage.import_dict(entries, target)
        print(f"Imported {count} entries into project: {target}")

    elif action == "clear":
        confirm = input(f"Clear all entries for project '{project or storage.get_current_project()}'? [y/N] ")
        if confirm.lower() == "y":
            storage.save_dict({"dict": {}, "rdict": {}, "types": {}}, project)
            print("Dictionary cleared.")
        else:
            print("Cancelled.")

    else:
        print("Usage: prompt-mask dict [list|add|remove|export|import|clear]")


# ════════════════════════════════════════
# Main
# ════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(
        prog="prompt-mask",
        description="Anonymize your prompts before sending them to AI.",
    )
    parser.add_argument("-V", "--version", action="store_true", help="Show version")
    parser.add_argument("-p", "--project", default=None, help="Project name (default: active project)")

    sub = parser.add_subparsers(dest="command")

    # seal
    p_seal = sub.add_parser("seal", help="Seal markers in text: ***{} ---{} +++{}")
    p_seal.add_argument("input", nargs="?", default=None, help="Text or file path (or pipe stdin)")
    p_seal.add_argument("-o", "--output", default=None, help="Output file (default: stdout)")
    p_seal.set_defaults(func=cmd_seal)

    # unseal
    p_unseal = sub.add_parser("unseal", help="Unseal text using dictionary")
    p_unseal.add_argument("input", nargs="?", default=None, help="Text or file path (or pipe stdin)")
    p_unseal.add_argument("-o", "--output", default=None, help="Output file (default: stdout)")
    p_unseal.set_defaults(func=cmd_unseal)

    # auto
    p_auto = sub.add_parser("auto", help="Auto-seal using existing dictionary (no markers needed)")
    p_auto.add_argument("input", nargs="?", default=None, help="Text or file path (or pipe stdin)")
    p_auto.add_argument("-o", "--output", default=None, help="Output file (default: stdout)")
    p_auto.add_argument("-y", "--yes", action="store_true", help="Skip confirmation")
    p_auto.set_defaults(func=cmd_auto)

    # scan
    p_scan = sub.add_parser("scan", help="Scan text for sensitive data (interactive)")
    p_scan.add_argument("input", nargs="?", default=None, help="Text or file path (or pipe stdin)")
    p_scan.add_argument("-o", "--output", default=None, help="Output file (default: stdout)")
    p_scan.set_defaults(func=cmd_scan)

    # project
    p_proj = sub.add_parser("project", help="Manage projects")
    p_proj.add_argument("action", choices=["list", "use", "create", "delete"], help="Action")
    p_proj.add_argument("name", nargs="?", default=None, help="Project name")
    p_proj.set_defaults(func=cmd_project)

    # dict
    p_dict = sub.add_parser("dict", help="Manage dictionary")
    p_dict.add_argument("action", choices=["list", "add", "remove", "export", "import", "clear"], help="Action")
    p_dict.add_argument("--real", default=None, help="Real value (for add/remove)")
    p_dict.add_argument("--fake", default=None, help="Fake value (for add)")
    p_dict.add_argument("--type", default=None, help="Type override (for add)")
    p_dict.add_argument("-o", "--output", default=None, help="Output file (for export)")
    p_dict.add_argument("-i", "--input", default=None, help="Input file (for import)")
    p_dict.set_defaults(func=cmd_dict)

    args = parser.parse_args()

    if args.version:
        print(f"prompt-mask {__version__}")
        return

    if not args.command:
        parser.print_help()
        return

    if args.project:
        storage.set_current_project(args.project)

    args.func(args)


if __name__ == "__main__":
    main()
