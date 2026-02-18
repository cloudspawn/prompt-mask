"""Detect sensitive data patterns in text."""

import re
from collections import Counter


def detect_all(text):
    """Scan text and return detected sensitive items grouped by type.

    Returns dict: { type: [(value, count), ...] }
    """
    findings = {}

    # ── Emails ──
    emails = re.findall(r"[\w.+-]+@[\w-]+\.[\w.]+", text)
    if emails:
        findings["email"] = _count(emails)

    # ── IPs ──
    ips = re.findall(r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b", text)
    if ips:
        findings["ip"] = _count(ips)

    # ── Phone numbers ──
    phones = re.findall(r"(?<!\d)(?:\+?\d{1,3}[\s.-]?)?\(?\d{2,4}\)?[\s.-]?\d{2,4}[\s.-]?\d{2,4}(?!\d)", text)
    # Filter out things that look like IPs or dates
    phones = [p.strip() for p in phones if len(re.sub(r"\D", "", p)) >= 8]
    if phones:
        findings["phone"] = _count(phones)

    # ── Dates ──
    dates = re.findall(r"\b\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}\b", text)
    dates += re.findall(r"\b\d{4}[/\-]\d{1,2}[/\-]\d{1,2}\b", text)
    if dates:
        findings["date"] = _count(dates)

    # ── Amounts (numbers with currency symbols or k/M suffixes) ──
    amounts = re.findall(r"\b\d[\d\s.,]*\s*[€$£¥kKmM%]+\b", text)
    if amounts:
        findings["amount"] = _count([a.strip() for a in amounts])

    # ── Names (two+ consecutive capitalized words, not at sentence start) ──
    # Find all capitalized word sequences
    name_candidates = re.findall(r"(?<![.!?]\s)(?<!\n)(?<=\s)([A-Z][a-zÀ-ÿ]+(?:[ \t]+[A-Z][a-zÀ-ÿ]+)+)", text)
    # Also catch at line start but filter common words
    name_candidates += re.findall(r"^([A-Z][a-zÀ-ÿ]+(?:[ \t]+[A-Z][a-zÀ-ÿ]+)+)", text, re.MULTILINE)
    # Deduplicate
    skip_words = {
        "Le", "La", "Les", "Un", "Une", "Des", "Du", "De", "The", "This",
        "That", "These", "Those", "And", "But", "For", "Not", "All", "Any",
        "Some", "Our", "Your", "His", "Her", "Its", "Mon", "Ton", "Son",
        "Notre", "Votre", "Leur", "Dans", "Pour", "Avec", "Sans", "Chez",
    }
    filtered = []
    for name in name_candidates:
        words = name.split()
        if words[0] in skip_words:
            continue
        # Skip if it looks like a sentence fragment (more than 4 words)
        if len(words) > 4:
            continue
        filtered.append(name)
    if filtered:
        findings["name"] = _count(filtered)

    # ── URLs ──
    urls = re.findall(r"https?://[^\s<>\"']+", text)
    if urls:
        findings["url"] = _count(urls)

    # ── API keys / tokens (long hex or base64 strings) ──
    tokens = re.findall(r"\b[a-zA-Z0-9_\-]{20,}\b", text)
    # Filter out common words and URLs
    tokens = [t for t in tokens if not t.startswith("http") and re.search(r"[0-9]", t) and re.search(r"[a-zA-Z]", t)]
    if tokens:
        findings["token"] = _count(tokens)

    return findings


def find_known_in_text(text, dictionary):
    """Find dictionary entries that appear in the text (for auto mode).

    Returns list of (real_value, fake_value, count, type)
    """
    found = []
    for real, fake in dictionary.items():
        count = text.count(real)
        if count > 0:
            found.append((real, fake, count))
    # Sort by length desc (replace longest first to avoid partial matches)
    return sorted(found, key=lambda x: len(x[0]), reverse=True)


def _count(items):
    """Count occurrences and return sorted list of (value, count)."""
    c = Counter(items)
    return sorted(c.items(), key=lambda x: (-x[1], x[0]))
