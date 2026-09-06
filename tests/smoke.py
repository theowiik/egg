"""Behavior checks for the generated shell, run by `nix flake check`."""
import os
from pathlib import Path
import subprocess
import tempfile
import time

preview = os.environ["PREVIEW"]
install = os.environ["INSTALL"]
root = Path(os.environ["PREVIEW_ROOT"])


def run(args, *, env=None, success=True):
    result = subprocess.run(args, env=env, text=True, capture_output=True, timeout=60)
    if success:
        assert result.returncode == 0, result.stdout + result.stderr
    else:
        assert result.returncode != 0, result.stdout + result.stderr
    return result.stdout + result.stderr


with tempfile.TemporaryDirectory() as temp:
    fake = Path(temp)
    (fake / "flake.nix").write_text("{}")
    (fake / ".zshenv").write_text("print INHERITED_CONFIG_LOADED; exit 99")
    (fake / ".zshrc").write_text("print INHERITED_CONFIG_LOADED; exit 99")
    env = dict(os.environ, HOME=temp, ZDOTDIR=temp, XDG_CONFIG_HOME=temp,
               XDG_DATA_HOME=temp, XDG_STATE_HOME=temp, XDG_CACHE_HOME=temp,
               GIT_CONFIG_GLOBAL=str(fake / "gitconfig"), STARSHIP_CONFIG=temp,
               __HM_SESS_VARS_SOURCED="1", __HM_ZSH_SESS_VARS_SOURCED="1",
               LAZYSHELL_DIR=temp, TERM="dumb")

    shell_checks = r'''
      set -ex
      [[ $HOME = /tmp/lazyshell-preview/home ]]
      [[ $PWD = $HOME && $ZDOTDIR = $HOME/.config/zsh ]]
      [[ $XDG_CONFIG_HOME = $HOME/.config && $XDG_STATE_HOME = $HOME/.local/state ]]
      [[ $XDG_DATA_HOME = $HOME/.local/share && $XDG_CACHE_HOME = $HOME/.cache ]]
      [[ -z ${GIT_CONFIG_GLOBAL:-} && $EDITOR = hx ]]
      original_path=$PATH
      mkcd "$HOME/a directory/child"
      up
      [[ $PWD = "$HOME/a directory" && $PATH = $original_path ]]
      up 0
      [[ $PWD = "$HOME/a directory" ]]
      up 01
      [[ $PWD = $HOME ]]
      if up nope || up -1 || up 1 2 || mkcd; then exit 21; fi
      nix() { printf '%s\n' "$@"; }
      [[ $(nsh ripgrep --offline) = $'shell\nnixpkgs#ripgrep\n--offline' ]]
      [[ $(nrun hello -- --help) = $'run\nnixpkgs#hello\n--\n--help' ]]
      unfunction nix
      mkdir "$HOME/stubs"
      printf '#!/bin/sh\nprintf "%%s\\n" "$@" > "$HOME/hm-args"\n' > "$HOME/stubs/home-manager"
      chmod +x "$HOME/stubs/home-manager"
      PATH="$HOME/stubs:$PATH" hms --dry-run
      [[ $(<"$HOME/hm-args") = $'switch\n--flake\n'$LAZYSHELL_DIR$'\n--dry-run' ]]
      PATH="$HOME/stubs:$PATH" hmn
      [[ $(<"$HOME/hm-args") = $'news\n--flake\n'$LAZYSHELL_DIR ]]
      mkdir "$HOME/files"
      cd "$HOME/files"
      target=$'target with\na newline'
      touch -- "$target"
      editor_test() { [[ $1 = --wait && $2 = -- && $3 -ef $target ]]; }
      EDITOR='editor_test --wait' FZF_DEFAULT_OPTS='--filter=target' ff target
      cd "$HOME"
      lazyshell help > help.txt
      lazyshell aliases > aliases.txt
      grep -q 'lazyshell switch' aliases.txt
      if lazyshell unknown > /dev/null 2>&1; then exit 22; fi
      lazyshell fetch > fetch.txt
      [[ $(<fetch.txt) != *$'\e'* ]]
      if lazyshell doctor > doctor.txt; then exit 23; fi
      grep -q 'placeholder' doctor.txt
      git config --global user.name 'Smoke Test'
      git config --global user.email 'smoke@lazyshell.test'
      lazyshell doctor
      mv "$XDG_CONFIG_HOME/starship.toml" "$HOME/starship.saved"
      if lazyshell doctor > doctor.txt; then exit 24; fi
      grep -q 'starship.toml missing' doctor.txt
      mv "$HOME/starship.saved" "$XDG_CONFIG_HOME/starship.toml"
      if PATH=/nonexistent @PROFILE@/bin/lazyshell doctor > doctor.txt; then exit 25; fi
      grep -q 'missing from PATH' doctor.txt
      zellij setup --check
      print SHELL_CHECKS_OK
    '''.replace("@PROFILE@", os.environ["PROFILE"])
    output = run([preview, "-ic", shell_checks], env=env)
    assert "SHELL_CHECKS_OK" in output and "INHERITED_CONFIG_LOADED" not in output, output
    assert "ready when you are" not in output, output
    assert not root.exists(), "preview was not cleaned up"
    assert not (fake / "gitconfig").exists(), "preview wrote to inherited Git config"

    # A real login shell with redirected stdout stays quiet.
    output = run([preview, "-ic", "print QUIET_OK"], env=dict(env, TERM="xterm-256color"))
    assert "QUIET_OK" in output and "ready when you are" not in output, output
    output = run([preview, "-c", "exit 7"], env=env, success=False)
    assert not root.exists(), "failed child left a stale lock"

    # Keep one session alive, then prove a second launch cannot remove its home.
    holder = subprocess.Popen([preview, "-c", 'touch "$HOME/../ready"; while [[ ! -f "$HOME/../release" ]]; do sleep 0.1; done'],
                              env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    try:
        deadline = time.monotonic() + 30
        while not (root / "ready").exists():
            if holder.poll() is not None or time.monotonic() > deadline:
                raise AssertionError("preview holder did not start")
            time.sleep(0.1)
        output = run([preview, "-c", "exit"], env=env, success=False)
        assert "preview already running" in output, output
        assert (root / "ready").exists(), "second preview disturbed the first"
        (root / "release").touch()
        stdout, stderr = holder.communicate(timeout=30)
        assert holder.returncode == 0, stdout + stderr
    finally:
        if holder.poll() is None:
            (root / "release").touch()
            holder.communicate(timeout=30)
    assert not root.exists(), "preview lock survived normal exit"

    # These install paths never activate a real configuration.
    assert "Usage:" in run([install, "--help"], env=env)
    output = run([install], env=dict(env, LAZYSHELL_DIR=str(fake / "missing")), success=False)
    assert "no flake.nix" in output, output

print("All lazyshell smoke checks passed")
