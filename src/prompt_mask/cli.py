"""Command line interface for prompt-mask."""

import sys
import argparse
from pathlib import Path
from . import __version__
from . import engine, storage


def read_input(source):
    """Read from file path, string argument, or stdin."""
    if source and Path(source).is_file():
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


def cmd_version(args):
    print(f"prompt-mask {__version__}")


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

    args = parser.parse_args()

    if args.version:
        cmd_version(args)
        return

    if not args.command:
        parser.print_help()
        return

    if args.project:
        storage.set_current_project(args.project)

    args.func(args)


if __name__ == "__main__":
    main()
