# 🥚 egg

A zsh environment defined in Nix: one prompt, one set of aliases, and about 40
command-line tools, reproduced identically on every machine you put it on.
Runs on Linux and Apple Silicon macOS.

Everything is Home Manager configuration in this repository — no dotfile
symlink scripts, no `curl | sh`. Try it in a throwaway home first; adopt it when
you like it.

## Try it

Install [Nix](https://nixos.org/download/), then:

```sh
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
git clone https://github.com/theowiik/egg.git ~/git/egg
cd ~/git/egg
nix run .#try
```

This opens a shell with a temporary home directory. Your own dotfiles are not
touched. Type `exit` to leave; the preview deletes itself.

## Install it

Add your machine under `homeConfigurations` in `flake.nix`, replacing the
username and hostname with your own:

```nix
"alice@thinkpad" = mkHome {
  system = "x86_64-linux"; # aarch64-linux and aarch64-darwin also work
  username = "alice";
  host = "personal";
};
```

The key must be `$USER@$(hostname)` for a bare `--flake .` to find it. Set your
Git identity in `hosts/personal.nix` with `egg.git.userName` and
`egg.git.userEmail`, then:

```sh
nix run .#install
exec ~/.nix-profile/bin/zsh -l
```

If you cloned somewhere other than `~/git/egg`, set `egg.directory` in your host
file or export `EGG_DIR`, so `egg switch` and `egg edit` find the repository.

## The `egg` command

| Command | What it does |
| --- | --- |
| `egg help` | every tool below, with one line each |
| `egg aliases` | every alias, generated from the config |
| `egg keys` | keybindings |
| `egg doctor` | check tools, config, activation and Git identity |
| `egg fetch` | system dashboard (passes flags to fastfetch) |
| `egg edit` | open this repository in `$EDITOR` |
| `hms` / `hmn` | apply configuration changes / read Home Manager news |

## Moving around

- `c` — pick a directory with a tree preview; `c ~/git` starts there instead.
- `z name` jumps to a directory you have visited; `zi` opens a picker.
- `..` / `...` go up one or two levels; `cd -` goes back.
- `mkcd dir` makes a directory and enters it. `ff pat` opens a file in the editor.
- **Ctrl-R** history, **Ctrl-T** file path, **Alt-C** directory, **Tab** completion menu.

Typing a command that has a shorter alias prints a one-line tip afterwards —
`git status --short --branch` suggests `gs`. The command still runs. Set
`EGG_NO_ALIAS_TIPS=1` in `~/.zshrc.local` to turn tips off.

## The tools

All of these are installed and on `$PATH`. `egg help` prints the same list with
current descriptions.

**Shell** — `eza` (ls with git status and tree view), `bat` (cat with
highlighting), `fzf` (fuzzy finder), `zoxide` (`z` jumping), `starship`
(prompt), `direnv` (per-project env from `.envrc`), `carapace` (completions for
CLIs that ship none), `zellij` (panes, tabs, sessions).

**Files & search** — `fd` (fast, gitignore-aware find), `rg` (ripgrep), `sd`
(`sd before after file`), `yy` (yazi, exits into the directory you left off in),
`ouch` (compress/extract without tar flags), `tree`, `dust` (what is eating the
disk), `duf` (readable `df`).

**Git** — `git` (delta diffs, `git lg`, `git st`), `lazygit` (stage hunks,
rebase, cherry-pick), `gh` (GitHub CLI), `difft` (diff that understands syntax).

**Editor** — `hx` (helix; modal, LSP built in, no config needed).

**Data** — `jq` (JSON), `yq` (YAML, XML, TOML), `jless` (browse big JSON),
`glow` (render markdown).

**System** — `btop` (processes and resources), `procs` (`ps` with colour and
search), `fastfetch` (system dashboard), `hyperfine` (benchmark a command with
warmup and stats), `watchexec` (re-run on file change).

**Network** — `xh` (HTTP without curl's flag soup), `doggo` (readable `dig`),
`gping` (ping plotted over time), `curl`, `wget`.

**Dev** — `just` (command runner reading a `justfile`), `tokei` (count lines by
language), `tldr` (examples instead of a man page), `unzip`.

**Linux only** — `xclip` (clipboard), `trash-put` (`rm` you can undo).
**macOS only** — GNU coreutils under `g` prefixes, since macOS ships old BSD ones.

## Layout

```
flake.nix          machines, plus `nix run .#try` and `.#install`
home.nix           what every machine gets
hosts/*.nix        per-machine settings (Git identity, extra packages)
modules/*.nix      the shared configuration, one file per concern
modules/options.nix  the `egg.*` options hosts set
lib/palette.nix    the colours everything else reads
tests/             smoke tests run by `nix flake check`
```

`egg.toolbox` in `modules/packages.nix` is one list that both installs the
packages and renders `egg help`, so the two cannot disagree. Adding a tool is
one entry.

## Changing it

```sh
nix run .#try         # try the change in a temporary home
nix flake check       # smoke tests
nix fmt               # nixfmt; must leave no diff
nix run .#install     # apply it for real
```

New modules go in `modules/` and must be listed in `modules/default.nix`.
Builds are expected to be warning-free — a `trace: warning: ... has been
renamed` from Home Manager means the option needs migrating.
