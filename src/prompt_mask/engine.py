"""Core seal/unseal engine — same logic as the web app."""

import re
import random
from . import storage

# ── Fake data pools (same as web) ──
FAKE_NAMES = [
    "Alex Morgan", "Sam Rivera", "Jordan Chen", "Casey Brooks",
    "Riley Park", "Quinn Foster", "Avery Lane", "Taylor Nash",
    "Morgan Ellis", "Jamie Cross", "Drew Palmer", "Blake Warren",
    "Reese Conrad", "Parker Stone", "Sage Mitchell", "Robin Clarke",
]
FAKE_COMPANIES = [
    "Vertex Labs", "NovaBridge", "Apex Dynamics", "Cobalt Systems",
    "IronLeaf Corp", "Prism Works", "Zenith Group", "Atlas Digital",
    "Onyx Partners", "Helix Solutions", "Lunar Industries", "Forge & Co",
]
FAKE_EMAILS = [
    "contact@vertex-labs.com", "info@novabridge.io", "hello@apex-dyn.com",
    "team@cobalt-sys.com", "admin@ironleaf.co", "mail@prismworks.io",
]
FAKE_PROJECTS = [
    "Project Horizon", "Project Nebula", "Project Titan", "Project Echo",
    "Project Meridian", "Project Onyx", "Project Vanguard", "Project Apex",
]

_counters = {"name": 0, "company": 0, "email": 0, "project": 0}


def detect_type(value):
    v = value.strip()
    if re.match(r"^[\w.+-]+@[\w-]+\.[\w.]+$", v):
        return "email"
    if re.search(r"\b(project|projet)\s", v, re.IGNORECASE):
        return "project"
    if re.search(r"\b(inc|corp|ltd|sas|sarl|gmbh|llc|group|labs?|co|tech|systems|dynamics|digital|solutions|partners|industries|works)\b", v, re.IGNORECASE):
        return "company"
    if re.match(r"^[\d\s.,]+[€$£¥kKmM%]*$", v):
        return "amount"
    return "name"


def generate_fake(value, type_name, existing_fakes=None):
    pools = {
        "email": FAKE_EMAILS,
        "company": FAKE_COMPANIES,
        "project": FAKE_PROJECTS,
        "name": FAKE_NAMES,
    }
    if type_name == "amount":
        return randomize_value(value)
    pool = pools.get(type_name, FAKE_NAMES)
    used = set(existing_fakes or [])
    for candidate in pool:
        if candidate not in used:
            return candidate
    # All used, cycle with counter
    key = type_name if type_name in _counters else "name"
    idx = _counters[key]
    _counters[key] = (idx + 1) % len(pool)
    return pool[idx]


def randomize_value(value):
    v = value.strip()

    # Try as amount
    m = re.match(r"^([^\d]*)(\d[\d\s.,]*)(\s*[€$£¥kKmM%]*.*)$", v)
    if m:
        prefix, num_str, suffix = m.groups()
        num_str = num_str.replace(" ", "").replace(",", "")
        try:
            num = float(num_str)
            factor = 0.7 + random.random() * 0.6
            return f"{prefix}{round(num * factor)}{suffix}"
        except ValueError:
            return v  # return original if date is invalid

    # Try as date
    m = re.match(r"^(\d{1,4})([\/-])(\d{1,2})\2(\d{1,4})$", v)
    if m:
        parts = [int(m.group(1)), int(m.group(3)), int(m.group(4))]
        sep = m.group(2)
        offset = random.randint(-30, 30)
        from datetime import date, timedelta
        try:
            if parts[2] > 31:  # dd/mm/yyyy
                d = date(parts[2], parts[1], parts[0])
            else:  # yyyy-mm-dd
                d = date(parts[0], parts[1], parts[2])
            d += timedelta(days=offset)
            if parts[2] > 31:
                return f"{d.day:02d}{sep}{d.month:02d}{sep}{d.year}"
            else:
                return f"{d.year}{sep}{d.month:02d}{sep}{d.day:02d}"
        except ValueError:
            return v  # return original if date is invalid

    # Shuffle preserving shape
    chars = list(v)
    for i in range(len(chars) - 1, 0, -1):
        c = chars[i]
        if c.islower():
            chars[i] = chr(random.randint(97, 122))
        elif c.isupper():
            chars[i] = chr(random.randint(65, 90))
        elif c.isdigit():
            chars[i] = str(random.randint(0, 9))
    return "".join(chars)


def seal(text, project=None):
    """Process markers in text, return sealed text and stats."""
    data = storage.load_dict(project)
    d = data["dict"]
    stats = {"anon": 0, "block": 0, "random": 0}
    redacted_map = {}
    redacted_idx = 0

    def replace_anon(m):
        value = m.group(1)
        stats["anon"] += 1
        if value in d:
            return d[value]
        t = detect_type(value)
        fake = generate_fake(value, t, existing_fakes=set(d.values()))
        data["dict"][value] = fake
        data["rdict"][fake] = value
        data["types"][value] = t
        return fake

    def replace_block(m):
        nonlocal redacted_idx
        value = m.group(1)
        stats["block"] += 1
        if value and value in redacted_map:
            return f"[REDACTED:{redacted_map[value]}]"
        redacted_idx += 1
        if value:
            redacted_map[value] = redacted_idx
        return f"[REDACTED:{redacted_idx}]"

    def replace_random(m):
        value = m.group(1)
        stats["random"] += 1
        if value in d:
            return d[value]
        fake = randomize_value(value)
        t = "amount" if re.search(r"[€$£¥%]", value) else "date" if re.search(r"\d", value) else "text"
        data["dict"][value] = fake
        data["rdict"][fake] = value
        data["types"][value] = t
        return fake

    result = re.sub(r"\*\*\*\{([^}]+)\}", replace_anon, text)
    result = re.sub(r"---\{([^}]*)\}", replace_block, result)
    result = re.sub(r"\+\+\+\{([^}]+)\}", replace_random, result)

    storage.save_dict(data, project)
    return result, stats


def unseal(text, project=None):
    """Replace fake values with real ones using reverse dictionary."""
    data = storage.load_dict(project)
    rdict = data.get("rdict", {})
    result = text
    # Sort by length desc to avoid partial replacements
    for fake in sorted(rdict.keys(), key=len, reverse=True):
        result = result.replace(fake, rdict[fake])
    return result


def auto_seal(text, project=None):
    """Replace known dictionary entries in text without markers."""
    data = storage.load_dict(project)
    d = data["dict"]
    result = text
    count = 0
    # Sort by length desc to avoid partial replacements
    for real in sorted(d.keys(), key=len, reverse=True):
        fake = d[real]
        occurrences = result.count(real)
        if occurrences > 0:
            result = result.replace(real, fake)
            count += occurrences
    return result, count
