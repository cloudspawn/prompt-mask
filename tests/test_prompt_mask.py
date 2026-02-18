"""Tests for prompt-mask engine, storage, and detector."""

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from prompt_mask import engine, storage, detector


@pytest.fixture(autouse=True)
def temp_storage(tmp_path):
    """Redirect storage to a temp dir for every test."""
    with patch.object(storage, "DEFAULT_DIR", tmp_path / ".prompt-mask"):
        storage.get_project_dir("default")
        yield tmp_path


# ════════════════════════════════════════
# Engine: detect_type
# ════════════════════════════════════════

class TestDetectType:
    def test_email(self):
        assert engine.detect_type("jean@nexus.com") == "email"

    def test_company_keywords(self):
        assert engine.detect_type("Nexus Tech") == "company"
        assert engine.detect_type("Cobalt Systems") == "company"
        assert engine.detect_type("IronLeaf Corp") == "company"

    def test_name(self):
        assert engine.detect_type("Jean Dupont") == "name"

    def test_amount(self):
        assert engine.detect_type("450k€") == "amount"

    def test_project(self):
        assert engine.detect_type("Project Alpha") == "project"


# ════════════════════════════════════════
# Engine: seal
# ════════════════════════════════════════

class TestSeal:
    def test_anonymize_name(self):
        result, stats = engine.seal("Hello ***{Jean Dupont}")
        assert "Jean Dupont" not in result
        assert stats["anon"] == 1

    def test_anonymize_consistency(self):
        engine.seal("***{Jean Dupont}")
        result1, _ = engine.seal("***{Jean Dupont}")
        result2, _ = engine.seal("***{Jean Dupont}")
        assert result1 == result2

    def test_block_redacted_numbered(self):
        result, stats = engine.seal("Password: ---{secret123}")
        assert "[REDACTED:1]" in result
        assert "secret123" not in result
        assert stats["block"] == 1

    def test_block_different_values_different_numbers(self):
        result, _ = engine.seal("---{pass1} and ---{pass2}")
        assert "[REDACTED:1]" in result
        assert "[REDACTED:2]" in result

    def test_block_same_value_same_number(self):
        result, _ = engine.seal("---{secret} then ---{secret}")
        assert result.count("[REDACTED:1]") == 2
        assert "[REDACTED:2]" not in result

    def test_block_not_stored_in_dict(self):
        engine.seal("---{my_password}")
        data = storage.load_dict()
        assert "my_password" not in data["dict"]

    def test_randomize_amount(self):
        result, stats = engine.seal("Budget: +++{450k€}")
        assert "450k€" not in result
        assert "k€" in result
        assert stats["random"] == 1

    def test_mixed_markers(self):
        text = "***{Jean Dupont} at ---{password} for +++{450k€}"
        result, stats = engine.seal(text)
        assert "Jean Dupont" not in result
        assert "password" not in result
        assert "450k€" not in result
        assert stats["anon"] == 1
        assert stats["block"] == 1
        assert stats["random"] == 1

    def test_no_markers(self):
        result, stats = engine.seal("Just plain text")
        assert result == "Just plain text"
        assert stats["anon"] == 0


# ════════════════════════════════════════
# Engine: unseal
# ════════════════════════════════════════

class TestUnseal:
    def test_unseal_reverses_seal(self):
        original = "Email ***{Jean Dupont} at ***{Nexus Tech}"
        sealed, _ = engine.seal(original)
        assert "Jean Dupont" not in sealed
        unsealed = engine.unseal(sealed)
        assert "Jean Dupont" in unsealed
        assert "Nexus Tech" in unsealed

    def test_unseal_no_dict_entries(self):
        result = engine.unseal("Nothing to unseal here")
        assert result == "Nothing to unseal here"


# ════════════════════════════════════════
# Engine: unique fakes
# ════════════════════════════════════════

class TestUniqueFakes:
    def test_different_names_get_different_fakes(self):
        storage.save_dict({"dict": {}, "rdict": {}, "types": {}})
        engine.seal("***{Jean Dupont} and ***{Marie Laurent}")
        data = storage.load_dict()
        fake_jean = data["dict"]["Jean Dupont"]
        fake_marie = data["dict"]["Marie Laurent"]
        assert fake_jean != fake_marie, f"Both mapped to {fake_jean}"


# ════════════════════════════════════════
# Engine: auto_seal
# ════════════════════════════════════════

class TestAutoSeal:
    def test_auto_replaces_known_entries(self):
        storage.add_mapping("Jean Dupont", "Alex Morgan", "name")
        storage.add_mapping("Nexus Tech", "Vertex Labs", "company")
        result, count = engine.auto_seal("Jean Dupont works at Nexus Tech")
        assert result == "Alex Morgan works at Vertex Labs"
        assert count == 2

    def test_auto_no_dict(self):
        result, count = engine.auto_seal("Nothing to replace")
        assert result == "Nothing to replace"
        assert count == 0

    def test_auto_multiple_occurrences(self):
        storage.add_mapping("Jean Dupont", "Alex Morgan", "name")
        result, count = engine.auto_seal("Jean Dupont met Jean Dupont")
        assert result == "Alex Morgan met Alex Morgan"
        assert count == 2


# ════════════════════════════════════════
# Storage
# ════════════════════════════════════════

class TestStorage:
    def test_add_and_load_mapping(self):
        storage.add_mapping("real", "fake", "name")
        data = storage.load_dict()
        assert data["dict"]["real"] == "fake"
        assert data["rdict"]["fake"] == "real"
        assert data["types"]["real"] == "name"

    def test_remove_mapping(self):
        storage.add_mapping("real", "fake", "name")
        storage.remove_mapping("real")
        data = storage.load_dict()
        assert "real" not in data["dict"]
        assert "fake" not in data["rdict"]

    def test_project_isolation(self):
        storage.add_mapping("real", "fake1", "name", project="proj1")
        storage.add_mapping("real", "fake2", "name", project="proj2")
        d1 = storage.load_dict("proj1")
        d2 = storage.load_dict("proj2")
        assert d1["dict"]["real"] == "fake1"
        assert d2["dict"]["real"] == "fake2"

    def test_current_project(self):
        storage.set_current_project("myproject")
        assert storage.get_current_project() == "myproject"

    def test_list_projects(self):
        storage.get_project_dir("alpha")
        storage.get_project_dir("beta")
        projects = storage.list_projects()
        assert "alpha" in projects
        assert "beta" in projects
        assert "default" in projects

    def test_delete_project(self):
        storage.get_project_dir("temp")
        storage.delete_project("temp")
        assert "temp" not in storage.list_projects()

    def test_cannot_delete_default(self):
        with pytest.raises(ValueError):
            storage.delete_project("default")

    def test_export_import_roundtrip(self):
        storage.add_mapping("Jean", "Alex", "name")
        storage.add_mapping("Nexus", "Vertex", "company")
        exported = storage.export_dict()
        assert len(exported["entries"]) == 2
        storage.save_dict({"dict": {}, "rdict": {}, "types": {}})
        count = storage.import_dict(exported["entries"])
        assert count == 2
        data = storage.load_dict()
        assert data["dict"]["Jean"] == "Alex"


# ════════════════════════════════════════
# Detector
# ════════════════════════════════════════

class TestDetector:
    def test_detect_email(self):
        findings = detector.detect_all("Contact jean@test.com for info")
        assert "email" in findings
        assert findings["email"][0][0] == "jean@test.com"

    def test_detect_ip(self):
        findings = detector.detect_all("Server at 192.168.1.42")
        assert "ip" in findings
        assert findings["ip"][0][0] == "192.168.1.42"

    def test_detect_date(self):
        findings = detector.detect_all("Meeting on 15/03/2025")
        assert "date" in findings
        assert findings["date"][0][0] == "15/03/2025"

    def test_detect_amount(self):
        findings = detector.detect_all("Budget is 450k€")
        assert "amount" in findings

    def test_detect_name(self):
        findings = detector.detect_all("Please contact Jean Dupont for details")
        assert "name" in findings
        assert any("Jean Dupont" in v for v, _ in findings["name"])

    def test_name_not_across_newlines(self):
        findings = detector.detect_all("Project Alpha\n\nJean Dupont is here")
        names = [v for v, _ in findings.get("name", [])]
        for name in names:
            assert "\n" not in name

    def test_detect_token(self):
        findings = detector.detect_all("Key: sk_live_a1b2c3d4e5f6g7h8i9j0")
        assert "token" in findings

    def test_find_known_in_text(self):
        d = {"Jean Dupont": "Alex Morgan", "Nexus Tech": "Vertex Labs"}
        found = detector.find_known_in_text("Jean Dupont at Nexus Tech", d)
        assert len(found) == 2

    def test_find_known_counts_occurrences(self):
        d = {"Jean": "Alex"}
        found = detector.find_known_in_text("Jean met Jean again", d)
        assert found[0][2] == 2

    def test_skip_common_words(self):
        findings = detector.detect_all("The Project is ready. Pour Les details.")
        names = [v for v, _ in findings.get("name", [])]
        for name in names:
            assert not name.startswith("The ")
            assert not name.startswith("Pour ")


# ════════════════════════════════════════
# CLI: read_input
# ════════════════════════════════════════

class TestReadInput:
    def test_read_from_string(self):
        from prompt_mask.cli import read_input
        assert read_input("hello world") == "hello world"

    def test_read_from_file(self, tmp_path):
        from prompt_mask.cli import read_input
        f = tmp_path / "test.txt"
        f.write_text("file content")
        assert read_input(str(f)) == "file content"

    def test_long_string_not_treated_as_file(self):
        from prompt_mask.cli import read_input
        long_text = "A" * 300
        assert read_input(long_text) == long_text
