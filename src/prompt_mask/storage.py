"""Dictionary and project storage in ~/.prompt-mask/"""

import json
from pathlib import Path

DEFAULT_DIR = Path.home() / ".prompt-mask"
DEFAULT_PROJECT = "default"


def get_config_path():
    return DEFAULT_DIR / "config.json"


def get_project_dir(project=None):
    project = project or get_current_project()
    d = DEFAULT_DIR / "projects" / project
    d.mkdir(parents=True, exist_ok=True)
    return d


def get_current_project():
    cfg = get_config_path()
    if cfg.exists():
        try:
            return json.loads(cfg.read_text()).get("current_project", DEFAULT_PROJECT)
        except (json.JSONDecodeError, KeyError):
            pass
    return DEFAULT_PROJECT


def set_current_project(name):
    cfg = get_config_path()
    cfg.parent.mkdir(parents=True, exist_ok=True)
    data = {}
    if cfg.exists():
        try:
            data = json.loads(cfg.read_text())
        except json.JSONDecodeError:
            pass
    data["current_project"] = name
    cfg.write_text(json.dumps(data, indent=2))


def load_dict(project=None):
    """Load dict, rdict, types for a project."""
    path = get_project_dir(project) / "dict.json"
    if path.exists():
        try:
            return json.loads(path.read_text())
        except json.JSONDecodeError:
            pass
    return {"dict": {}, "rdict": {}, "types": {}}


def save_dict(data, project=None):
    """Save dict, rdict, types for a project."""
    path = get_project_dir(project) / "dict.json"
    path.write_text(json.dumps(data, indent=2))


def add_mapping(real, fake, type_name="identity", project=None):
    """Add a single mapping and save."""
    data = load_dict(project)
    data["dict"][real] = fake
    data["rdict"][fake] = real
    data["types"][real] = type_name
    save_dict(data, project)
    return data


def remove_mapping(real, project=None):
    """Remove a single mapping and save."""
    data = load_dict(project)
    fake = data["dict"].pop(real, None)
    data["types"].pop(real, None)
    if fake:
        data["rdict"].pop(fake, None)
    save_dict(data, project)
    return data
