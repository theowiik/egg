"""Build the real onboarding path with temporary settings; never activate.

Run outside the Nix build sandbox: python3 tests/onboarding.py.
"""
import os
from pathlib import Path
import subprocess
import shutil
import tempfile

nix = ['nix', '--extra-experimental-features', 'nix-command flakes']
repo = str(Path(__file__).resolve().parents[1])
installer = subprocess.check_output(nix + ['build', '--no-link', '--print-out-paths', repo + '#install'], text=True).strip() + '/bin/egg-install'
with tempfile.TemporaryDirectory(prefix='egg-integration-') as temp:
    root = Path(temp)
    home = root / 'home'
    home.mkdir()
    checkout = root / 'checkout with spaces'
    checkout.mkdir()
    # Copy tracked working files into a temporary Git checkout, then create ignored
    # configs there. This catches accidentally importing the filtered store source.
    tracked = subprocess.check_output(['git', '-C', repo, 'ls-files', '-z']).decode().split('\0')
    for name in filter(None, tracked):
        source = Path(repo) / name
        if source.is_file():
            target = checkout / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
    subprocess.run(['git', 'init', '-q', str(checkout)], check=True)
    subprocess.run(['git', '-C', str(checkout), 'add', '.'], check=True)
    local = checkout / 'configs/personal.nix'
    env = dict(os.environ, HOME=str(home), EGG_DIR=str(checkout),
               XDG_CONFIG_HOME=str(home / '.config'), XDG_CACHE_HOME=str(home / '.cache'),
               XDG_DATA_HOME=str(home / '.local/share'), XDG_STATE_HOME=str(home / '.local/state'),
               NIX_CONFIG='experimental-features = nix-command flakes')
    env.pop('EGG_CONFIG', None)
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
    subprocess.run(['git', '-C', str(checkout), 'check-ignore', 'configs/personal.nix'], check=True)
    work = checkout / 'configs/work.nix'
    work.write_text('{ ... }: { egg.git.userName = "Work User"; egg.git.userEmail = "work@egg.test"; }')
    subprocess.run([installer, '--config', 'work', '--build'], cwd=temp, env=env, check=True)
    generation = (root / 'result').resolve()
    gitconfig = generation / 'home-files/.config/git/config'
    if not gitconfig.exists():
        gitconfig = generation / 'home-files/.gitconfig'
    assert 'Work User' in gitconfig.read_text()
    assert str(work) in (generation / 'home-path/bin/egg').read_text()
    subprocess.run(['git', '-C', str(checkout), 'check-ignore', 'configs/work.nix'], check=True)
    print('NAMED_CONFIG_BUILD_OK', flush=True)
