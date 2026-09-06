# lazyshell

A portable shell environment: Nix flakes + home-manager, one repo, same zsh on
every machine. Linux and macOS, no root, nothing touched outside `$HOME`.

Supported platforms: x86_64/aarch64 Linux and Apple Silicon macOS. The pinned
Nixpkgs release no longer supports Intel macOS.

Around 40 curated tools with defaults already set: helix, lazygit, zellij, yazi,
eza as `ls`, fzf, zoxide, ripgrep, fd, bat, and the usual suspects.

**`lazyshell help`** lists every one of them with a line on what it's for —
generated from the config, so it can't go stale. Also `lazyshell aliases`,
`lazyshell keys`, `lazyshell doctor`, and **`lazyshell fetch`**.

The terminal uses a coordinated Catppuccin Mocha palette: a framed two-line
prompt, rounded fuzzy finder, highlighted Git panes, and matching editor and
multiplexer. The prompt shows Git changes, Nix shells, slow commands, background
jobs, exit codes, and your hostname over SSH. No Nerd Font is required for the
prompt or dashboard.

A custom fastfetch dashboard welcomes interactive login shells with live CPU,
memory, disk, uptime, and workspace details. It uses local information only and
hides the logo below 80 columns. Run `lazyshell fetch` anytime, or use
`lazyshell fetch --logo none` for a compact summary; other fastfetch flags work too.
To silence the welcome, add `export LAZYSHELL_NO_WELCOME=1` to `~/.zshrc.local`,
or set `lazyshell.welcome.enable = false;` in your host config and rebuild.

```
flake.nix     inputs + one entry per machine
home.nix      shared base
hosts/        per-machine identity and extra packages
modules/      zsh, completions, aliases, packages, eza, editor, tui, git,
              prompt, navigation, help
```

Machine-specific things go in `hosts/`, never in `modules/` — that's what keeps
`git pull` conflict-free. Secrets go in `~/.zshrc.local`, which the config sources
and git never sees.

## Try it without installing anything

```sh
nix run .#try
```

Builds the config against a throwaway `$HOME` and drops you into it. `exit` and
it's gone; your dotfiles are never touched. (`nix develop` is different — that's
for working *on* this repo.)

## Install on a new machine

```sh
# 1. Nix
sh <(curl -L https://nixos.org/nix/install) --daemon      # open a new terminal after

# 2. Flakes are still behind a feature flag
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# 3. Clone (the `hms` alias assumes this path)
git clone git@github.com:theowiik/lazyshell.git ~/git/lazyshell
```

**4. Add this machine to `flake.nix`.** home-manager looks for an entry named
`$USER@$(hostname)` (FQDN, long and short, then plain `$USER`), so name it to
match and everything else is automatic:

```nix
"alice@thinkpad" = mkHome {
  system = "x86_64-linux";      # aarch64-darwin on Apple Silicon
  username = "alice";
  host = "personal";            # which file in hosts/
};
```

**5. Activate.** First run needs home-manager from the flake; `-b backup` renames
any dotfile in the way instead of failing:

```sh
nix run home-manager/master -- switch -b backup --flake ~/git/lazyshell
hms                                    # from now on (alias for the same thing)
```

**6. Make zsh your login shell.** Your zshrc lives at `~/.config/zsh/.zshrc`;
home-manager writes a `~/.zshenv` pointing there, so any zsh works:

```sh
chsh -s "$(command -v zsh)"            # macOS already defaults to zsh
```

## Changing things

| | |
|---|---|
| package everywhere | add an entry to the toolbox in `modules/packages.nix`, run `hms` |
| package on one machine | `lazyshell.extraPackages` in that `hosts/*.nix` |
| alias | `modules/aliases.nix` (or `modules/eza.nix` for `ls`-family) |
| configure a tool properly | new file in `modules/`, list it in `modules/default.nix` |

Find package names with `nix search nixpkgs foo`, try one with
`nix shell nixpkgs#foo`, and browse home-manager's options with
`man home-configuration.nix`.

Update versions (pinned in `flake.lock`, so nothing moves until you say so):

```sh
nix flake update && hms && git commit -am 'flake: update inputs'
```

## Syncing machines

```sh
hms && git commit -am '...' && git push      # here
cd ~/git/lazyshell && git pull && hms        # there
```

`flake.lock` pins the exact nixpkgs revision, so both machines get identical
builds. To undo: `home-manager generations`, then run the `activate` script of an
older one.
