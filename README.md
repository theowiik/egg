# 🥚 egg

A zsh environment defined in Nix: one prompt, one set of aliases, and about 40
terminal tools, reproduced identically on every machine you put it on. Runs on
Linux and Apple Silicon macOS.

Everything is Home Manager configuration in this repository. There are no
dotfile symlink scripts and no `curl | sh`. Try it in a throwaway home first,
then adopt it when you like it.

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
|---|---|
| `egg help` | every tool below, with one line each |
| `egg aliases` | every alias, generated from the config |
| `egg keys` | keybindings |
| `egg doctor` | check tools, config, activation and Git identity |
| `egg fetch` | system dashboard (passes flags to fastfetch) |
| `egg edit` | open this repository in `$EDITOR` |
| `hms` / `hmn` | apply configuration changes / read Home Manager news |

## Moving around

| Command | What it does |
|---|---|
| `c [dir]` | pick a directory with a tree preview, starting here or at `dir` |
| `z name` | jump to a directory you have visited; `zi` opens a picker |
| `..` / `...` | go up one or two levels; `cd -` goes back |
| `mkcd dir` | make a directory and enter it |
| `ff [pat]` | fuzzy find a file and open it in the editor |
| `Ctrl+R` | search shell history |
| `Ctrl+T` | insert a file path |
| `Alt+C` | change into a directory |
| `Tab` | completion menu, arrows to pick |

Typing a command that has a shorter alias prints a one line tip afterwards, so
`git status --short --branch` suggests `gs`. The command still runs. Set
`EGG_NO_ALIAS_TIPS=1` in `~/.zshrc.local` to turn tips off.

## The tools

All of these are installed and on `$PATH`. `egg help` prints the same list with
current descriptions.

### Shell

| Tool | What it does |
|---|---|
| `eza` | ls with git status and a tree view |
| `bat` | cat with syntax highlighting, and colour in man pages |
| `fzf` | fuzzy finder behind the history and file pickers |
| `zoxide` | `z foo` jumps to the directory you use most matching foo |
| `starship` | the prompt |
| `direnv` | per project environment from `.envrc`, applied on cd |
| `carapace` | completions for the many CLIs that ship none |
| `zellij` | terminal multiplexer: panes, tabs, sessions |

### Files and search

| Tool | What it does |
|---|---|
| `fd` | find, but fast and aware of `.gitignore` |
| `rg` | recursive grep, fast |
| `sd` | sed for humans: `sd before after file` |
| `yy` | yazi file manager; exits into the directory you left off in |
| `ouch` | compress and extract without remembering tar flags |
| `tree` | directory tree |
| `dust` | what is eating the disk |
| `duf` | df with readable output |

### Git

| Tool | What it does |
|---|---|
| `git` | configured with delta diffs and aliases (`git lg`, `git st`) |
| `lazygit` | full screen git UI: stage hunks, rebase, cherry pick |
| `gh` | GitHub CLI: PRs, issues, releases |
| `difft` | structural diff that understands syntax |

### Editor

| Tool | What it does |
|---|---|
| `hx` | helix: modal editor, LSP built in, no config needed |

### Data

| Tool | What it does |
|---|---|
| `jq` | JSON processor |
| `yq` | the same for YAML, XML and TOML |
| `jless` | browse a big JSON file interactively |
| `glow` | render markdown in the terminal |

### System

| Tool | What it does |
|---|---|
| `btop` | process and resource monitor |
| `procs` | ps with colour and search |
| `fastfetch` | system dashboard, also `egg fetch` |
| `hyperfine` | benchmark a command properly, with warmup and stats |
| `watchexec` | rerun a command when files change |

### Network

| Tool | What it does |
|---|---|
| `xh` | HTTP requests without curl's flag soup |
| `doggo` | dig with readable output |
| `gping` | ping, plotted over time |
| `curl` | still the one for scripts |
| `wget` | download a file |

### Dev

| Tool | What it does |
|---|---|
| `just` | project command runner; reads a `justfile` |
| `tokei` | count lines of code by language |
| `tldr` | practical examples instead of a man page |
| `unzip` | because something always needs it |

### Per platform

| Tool | What it does |
|---|---|
| `xclip` | Linux: clipboard from the terminal |
| `trash-put` | Linux: rm that you can undo |
| `g<tool>` | macOS: GNU coreutils, since macOS ships ancient BSD ones |

## Layout

```
flake.nix            machines, plus `nix run .#try` and `.#install`
home.nix             what every machine gets
hosts/*.nix          per machine settings (Git identity, extra packages)
modules/*.nix        the shared configuration, one file per concern
modules/options.nix  the `egg.*` options hosts set
lib/palette.nix      the colours everything else reads
tests/               smoke tests run by `nix flake check`
```

`egg.toolbox` in `modules/packages.nix` is one list that both installs the
packages and renders `egg help`, so the two cannot disagree. Adding a tool is
one entry.

## Changing it

```sh
nix run .#try         # try the change in a temporary home
nix flake check       # smoke tests
nix fmt               # nixfmt, must leave no diff
nix run .#install     # apply it for real
```

New modules go in `modules/` and must be listed in `modules/default.nix`.
Builds are expected to be free of warnings. A Home Manager
`trace: warning: ... has been renamed` means the option needs migrating.
