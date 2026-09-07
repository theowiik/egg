# 🥚 egg

A small zsh environment defined in Nix: a prompt, fuzzy finding, and ten
terminal tools, reproduced identically on every machine you put it on. Runs on
Linux and Apple Silicon macOS.

It stays out of the way of the shell you already know. Apart from `ls`, which
runs eza, no standard command is aliased to something else, so what you learn
here is plain zsh, plain git and plain coreutils.

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
| `egg edit` | open this repository in `$EDITOR` |
| `hms` / `hmn` | apply configuration changes / read Home Manager news |

## Moving around

| Command | What it does |
|---|---|
| `c [dir]` | pick a directory with a tree preview, starting here or at `dir` |
| `mkcd dir` | make a directory and enter it |
| `ff [pat]` | fuzzy find a file and open it in the editor |
| `cd ..`, `cd -` | go up, go back; `AUTO_CD` means `foo/` alone works too |
| `Ctrl+R` | fuzzy search shell history |
| `Ctrl+T` | insert a file path |
| `Alt+C` | change into a directory |
| `Tab` | completion menu, arrows to pick |

The only shell aliases are `ls`, plus `hms` and `hmn` for applying the
configuration and reading Home Manager news. Run `egg aliases` to see them.

## The tools

Ten tools, all installed and on `$PATH`. Only `ls` is aliased over a standard
command; `cat`, `du`, `ps` and `grep` still run the real thing. `egg help`
prints the same list with current descriptions.

| Tool | What it does |
|---|---|
| `eza` | ls with git status, icons and a tree view; `ls` is aliased to it |
| `bat` | cat with syntax highlighting, and colour in man pages |
| `fzf` | fuzzy finder behind history, file and directory pickers |
| `starship` | the prompt |
| `fd` | find, but fast and aware of `.gitignore`; backs the fzf widgets |
| `rg` | recursive grep, fast |
| `git` | configured with delta diffs and a few log aliases |
| `hx` | helix: modal editor, LSP built in, no config needed |
| `curl` | still the one for scripts |
| `wget` | download a file |

The list is meant to grow slowly. Add a tool as one entry in `egg.toolbox` in
`modules/packages.nix` when you find yourself wanting it, or per machine
through `egg.extraPackages` in your host file.

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
