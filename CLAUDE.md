# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commit after every change

Commit as soon as a change is complete and verified — don't leave the tree dirty
at the end of a turn. One commit per logical change, message explaining *why*.
Push only when asked.

## Environment gotchas

**Flakes are not enabled** in this machine's `~/.config/nix/nix.conf`. Every
command below needs the flag; without it nix fails with "experimental feature":

```sh
nix --extra-experimental-features 'nix-command flakes' <cmd>
```

**Nix only sees git-tracked files.** In a git repo, flakes ignore untracked
files, so a new `modules/*.nix` is invisible until `git add`. Run `git add -A`
before any build after creating a file, or the error will be a confusing
"file not found".

## Verify

```sh
nix build --no-link '.#homeConfigurations."oet@puter".activationPackage'   # Linux, builds
nix eval --raw '.#homeConfigurations."theo@work".activationPackage.drvPath' # macOS, evaluates only
nix flake check
nix fmt                                                                     # nixfmt, must leave no diff
nix run .#try                                                               # real zsh in a sandbox $HOME
```

Builds must be **warning-free**. home-manager master renames options often; a
`trace: warning: ... has been renamed` means migrate, don't ignore. Already
migrated: `programs.git.{userName,aliases,extraConfig}` → `programs.git.settings`,
`programs.git.delta` → `programs.delta`, `fzf.{file,changeDir}Widget{Command,Options}`
→ `fzf.<widget>.{command,options}`, `stdenv.isLinux` → `stdenv.hostPlatform.isLinux`,
`programs.zsh.initExtra` → `initContent`.

Two home-manager defaults that bite: `programs.zellij.enableZshIntegration`
auto-starts zellij in *every* shell (kept off), and `programs.helix.defaultEditor`
sets `EDITOR` — so `home.nix` must not set it too.

**Never run `home-manager switch`** unprompted — it rewrites the user's real
dotfiles. Use `nix run .#try` to test behaviour instead.

## Architecture

`flake.nix` defines a `mkHome` helper and one `homeConfigurations."user@host"`
entry per machine. The key format matters: home-manager resolves a bare
`--flake <path>` by looking for `$USER@$(hostname -f|hostname|hostname -s)`, then
plain `$USER`.

Three layers, and putting a change in the wrong one is the main way to break this
repo:

- `modules/*.nix` — shared by every machine. Cross-platform differences branch on
  `pkgs.stdenv.hostPlatform.isDarwin/isLinux`.
- `hosts/*.nix` — per-machine. Anything that differs between work and personal
  belongs here, otherwise `git pull` conflicts between machines.
- `modules/options.nix` — the `lazyshell.*` option namespace (`profile`,
  `git.userEmail`, `extraPackages`) that hosts set declaratively.

New modules go in `modules/` **and** must be listed in `modules/default.nix`.

### The toolbox is one list

`lazyshell.toolbox` in `modules/packages.nix` is the single source of truth: it
installs the packages *and* renders `lazyshell help` (`modules/help.nix`). Adding
a tool means one entry, never two. `package = null` means a `programs.*` module
already installs it — the entry stays so the tool is still discoverable in help.

Help text is rendered at build time from `config`, including the alias list from
`home.shellAliases`, so it cannot drift. Don't hand-write tool lists anywhere.

### zsh assembly order

Several modules write into one `.zshrc`, so ordering is explicit:

- `lib.mkOrder 550` — emitted **before** `compinit`. `fpath` changes must go here
  (`modules/completions.nix`) or completions silently won't load.
- `lib.mkOrder 1000` — end of `.zshrc`: options, keybindings, functions, zstyles.

Completions come from the packages themselves: each installs `_eza`, `_gh`, `_fd`
… into `$out/share/zsh/site-functions`, which reaches `$fpath` via
`config.home.profileDirectory` (`~/.nix-profile`). Nothing is vendored.

### Two subtleties worth not re-discovering

`programs.eza.enableZshIntegration = false` only suppresses home-manager's own
`ls`/`ll`/`la` aliases — the `eza = "eza <options>"` alias is emitted regardless.
Our `ls = "eza"` in `modules/eza.nix` inherits `--git`/`--icons`/`--header`
through zsh expanding the alias twice. Removing either alias silently drops the
options.

`nix run .#try` uses a **fixed** sandbox path (`/tmp/lazyshell-try`), not
`mktemp`, because home-manager bakes absolute `$HOME` paths into the generated
files at build time. The path must be known before the config is built.
