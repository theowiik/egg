"""Exercise the real installer script with a recording Home Manager, never activate."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

with tempfile.TemporaryDirectory(prefix="egg install ") as temp:
    root = Path(temp)
    repo = root / "checkout with spaces"
    repo.mkdir()
    (repo / "flake.nix").write_text("{}")
    home = root / "home with spaces"
    home.mkdir()
    stub = root / "home-manager"
    stub.write_text(f"#!{sys.executable}\n" + '''import json, os, sys
with open(os.environ["RECORD"], "w") as f:
    json.dump({"args": sys.argv[1:], "env": dict(os.environ)}, f)
''')
    stub.chmod(0o755)
    record = root / "record.json"
    env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}", HOME=str(home),
               XDG_CONFIG_HOME=str(home / "settings"), EGG_DIR=str(repo),
               EGG_SYSTEM="wrong", EGG_USERNAME="wrong", USER="wrong", RECORD=str(record))
    env.pop("EGG_CONFIG", None)
    script = os.environ["INSTALL_SCRIPT"]

    def run(*args, success=True, **overrides):
        record.unlink(missing_ok=True)
        result = subprocess.run([os.environ["BASH"], script, *args], env=env | overrides,
                                text=True, capture_output=True, timeout=30)
        assert (result.returncode == 0) == success, result.stderr
        return result, json.loads(record.read_text()) if record.exists() else None

    result, data = run("--build", "--show-trace")
    assert "Git identity will be unset" in result.stderr
    assert data["args"] == ["build", "-b", "backup", "--impure", "--flake", f"{repo}#current", "--show-trace"]
    assert data["env"]["EGG_SYSTEM"] == os.environ["SYSTEM"]
    assert data["env"]["EGG_USERNAME"] != "wrong"
    assert data["env"]["EGG_HOME"] == str(home)
    local = Path(data["env"]["EGG_CONFIG"])
    assert local == repo / "configs/personal.nix"
    local.parent.mkdir(parents=True)
    local.write_text("{}")
    result, data = run("--dry-run")
    assert not result.stderr and data["args"][0] == "switch"
    assert data["args"][-1] == "--dry-run"
    result, data = run("--news", EGG_CONFIG=str(local))
    assert data["args"][0] == "news" and data["env"]["EGG_CONFIG"] == str(local)
    work = repo / "configs/work.nix"
    work.write_text("{}")
    result, data = run("--config", "work", "--build", EGG_CONFIG=str(local))
    assert data["env"]["EGG_CONFIG"] == str(work) and data["args"][0] == "build"
    result, data = run("--news", "--config", "work")
    assert data["env"]["EGG_CONFIG"] == str(work) and data["args"][0] == "news"
    for args in [("--config",), ("--config", "../work"), ("--config", "work.nix")]:
        result, data = run(*args, success=False)
        assert "--config needs a name" in result.stderr and data is None
    result, data = run("--config", "missing", success=False)
    assert "config not found" in result.stderr and data is None
    result, data = run("--help")
    assert "Usage:" in result.stdout and data is None
    result, data = run(success=False, EGG_CONFIG="relative.nix")
    assert "absolute paths" in result.stderr and data is None
    result, data = run(success=False, EGG_DIR=str(root / "missing"))
    assert "no flake.nix" in result.stderr and data is None
    result, data = run(success=False, EGG_CONFIG=str(home))
    assert "not a file" in result.stderr and data is None
    result, data = run("--build", XDG_CONFIG_HOME="")
    assert data["env"]["EGG_CONFIG"] == str(local)
print("All installer checks passed")
