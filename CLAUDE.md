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
nix eval --raw '.#homeConfigurations.neo.activationPackage.drvPath' # macOS, evaluates only
nix flake check
python3 tests/onboarding.py                                               # real installer, build only
nix fmt                                                                     # nixfmt, must leave no diff
nix run .#try                                                               # real zsh in a sandbox $HOME
```

Builds must be **warning-free**. home-manager master renames options often; a
`trace: warning: ... has been renamed` means migrate, don't ignore. Already
migrated: `programs.git.{userName,aliases,extraConfig}` → `programs.git.settings`,
`programs.git.delta` → `programs.delta`, `fzf.{file,changeDir}Widget{Command,Options}`
→ `fzf.<widget>.{command,options}`, `stdenv.isLinux` → `stdenv.hostPlatform.isLinux`,
`programs.zsh.initExtra` → `initContent`.

One home-manager default that bites: `programs.helix.defaultEditor` sets
`EDITOR`, so `home.nix` must not set it too.

**Never run `home-manager switch`** unprompted — it rewrites the user's real
dotfiles. Use `nix run .#try` to test behaviour instead.

## Architecture

`flake.nix` defines `mkHome` for previews, runtime installs and the retained
named configurations. `nix run .#install` detects the username with `id -un`,
uses `$HOME`, and passes its Nix package system (no uname parsing). It exports
`EGG_SYSTEM`, `EGG_USERNAME`, `EGG_HOME`, `EGG_DIR`, and `EGG_CONFIG`, then calls
the pinned Home Manager with `--impure --flake "$EGG_DIR#current"`.
`homeConfigurations.current` exists only when `EGG_SYSTEM` is supplied;
normal pure evaluation never accesses runtime settings.

`lib/runtime-home.nix` combines runtime values with a Home Manager module in
`configs/<name>.nix`. The installer defaults to `configs/personal.nix`;
`--config <name>` selects another file and takes precedence over an absolute
`EGG_CONFIG` override. Rebuilds remember the selected path. `configs/*.nix`
are Git-ignored except `configs/example.nix`; read the live absolute path,
not a path relative to the Git-filtered flake source. No `git add` is needed
for user configs. An explicitly named config must exist.
`--build` builds without activation; `--news` shows news. `egg switch`/`hms`
and `egg news`/`hmn` use this installer too. Previews remain hermetic.

- `modules/*.nix` — shared by every machine. Cross-platform differences branch on
  `pkgs.stdenv.hostPlatform.isDarwin/isLinux`.
- `hosts/*.nix` — shared profiles, conditional on `egg.profile`. No personal identity.
- `modules/options.nix` — the `egg.*` options; identity defaults to empty.
- `configs/*.nix` — one small user config per file: identity, profile and packages.
  New adopters edit these files in the checkout, never the shared flake.

New modules go in `modules/` **and** must be listed in `modules/default.nix`.

### The toolbox is one list, and it is deliberately short

The toolbox was trimmed to ten core tools on purpose: eza, bat, fzf, starship,
fd, rg, git, hx, curl, wget. `ls` is the one standard command that is aliased
away (to eza, in `modules/eza.nix`); `cat`, `du`, `ps` and `grep` are the real
ones, because the point is to learn the originals. The conventional git
shorthands (`g`, `gs`, `gd`, …) are wanted and stay. Don't reintroduce further
replacement aliases or add tools speculatively; add one when it is wanted.

`egg.toolbox` in `modules/packages.nix` is the single source of truth: it
installs the packages *and* renders `egg help` (`modules/help.nix`). Adding
a tool means one entry, never two. `package = null` means a `programs.*` module
already installs it — the entry stays so the tool is still discoverable in help.

Help text is rendered at build time from `config`, including the alias list from
`home.shellAliases`, so it cannot drift. Don't hand-write tool lists anywhere.

### zsh assembly order

Several modules write into one `.zshrc`, so ordering is explicit:

- `lib.mkOrder 550` — emitted **before** `compinit`. `fpath` changes must go here
  (`modules/completions.nix`) or completions silently won't load.
- `lib.mkOrder 1000` — end of `.zshrc`: options, keybindings, functions, zstyles.

Completions come from the packages themselves: each installs `_eza`, `_fd`, `_rg`
… into `$out/share/zsh/site-functions`, which reaches `$fpath` via
`config.home.profileDirectory` (`~/.nix-profile`). Nothing is vendored.

### Two subtleties worth not re-discovering

`programs.eza.enableZshIntegration = false` only suppresses home-manager's own
`ls`/`ll`/`la` aliases — the `eza = "eza <options>"` alias is emitted regardless.
Our `ls = "eza"` in `modules/eza.nix` inherits `--git`/`--icons`/`--header`
through zsh expanding the alias twice. Removing either alias silently drops the
options.

`nix run .#try` uses a **fixed** home (`/tmp/egg-preview/home`) because
home-manager embeds absolute paths. The launcher atomically creates the parent
as a lock, refuses an existing directory, starts with a clean environment, and
removes its own preview on exit. It is a configuration preview, not a filesystem
sandbox. Its shell accepts arguments for smoke tests.

`lib/palette.nix` owns the shell UI colors. `modules/helpers.zsh` and
`modules/doctor.sh` are embedded in the generated shell/CLI. `nix flake check`
runs `tests/smoke.py` against a built preview, including helpers, diagnostics,
environment isolation, concurrent sessions and cleanup. Use
`--all-systems --no-build` to evaluate other platforms without a cross-platform builder.
