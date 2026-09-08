"""Build the real onboarding path with temporary settings; never activate.

Run outside the Nix build sandbox: python3 tests/onboarding.py.
"""
import os
from pathlib import Path
import subprocess
import tempfile

nix = ['nix', '--extra-experimental-features', 'nix-command flakes']
repo = str(Path(__file__).resolve().parents[1])
installer = subprocess.check_output(nix + ['build', '--no-link', '--print-out-paths', repo + '#install'], text=True).strip() + '/bin/egg-install'
with tempfile.TemporaryDirectory(prefix='egg-integration-') as temp:
    root = Path(temp)
    home = root / 'home'
    home.mkdir()
    local = root / 'local settings.nix'
    env = dict(os.environ, HOME=str(home), EGG_DIR=repo, EGG_CONFIG=str(local),
               XDG_CONFIG_HOME=str(home / '.config'), XDG_CACHE_HOME=str(home / '.cache'),
               XDG_DATA_HOME=str(home / '.local/share'), XDG_STATE_HOME=str(home / '.local/state'),
               NIX_CONFIG='experimental-features = nix-command flakes')
    for identity in [None, 'First User', 'Updated User']:
        if identity:
            local.write_text('{ ... }: { egg.git.userName = "' + identity + '"; egg.git.userEmail = "user@egg.test"; }')
        subprocess.run([installer, '--build'], cwd=temp, env=env, check=True)
        generation = (root / 'result').resolve()
        gitconfig = generation / 'home-files/.config/git/config'
        if not gitconfig.exists():
            gitconfig = generation / 'home-files/.gitconfig'
        text = gitconfig.read_text()
        assert (identity or 'name = ""') in text, text
        assert not (home / '.zshenv').exists(), 'build activated dotfiles'
        print('REAL_INSTALL_BUILD_OK', identity or 'missing settings', flush=True)
