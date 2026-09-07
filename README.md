# 🥚 egg

A ready-to-use zsh setup with playful cyan, lavender, pink, and mint colors,
a clean egg prompt, live clock, and framed file pickers. For Linux and Apple Silicon macOS.

## Get started

Install [Nix](https://nixos.org/download/), then open a new terminal and run:

```sh
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
git clone https://github.com/theowiik/lazyshell.git ~/git/lazyshell
cd ~/git/lazyshell
nix run .#try
```

This opens a preview with a temporary home. Your dotfiles stay untouched.
Type `exit` to leave.

## Make it permanent

Add your machine under `homeConfigurations` in `flake.nix`, replacing the
username and hostname with your own:

```nix
"alice@thinkpad" = mkHome {
  system = "x86_64-linux"; # aarch64-linux or aarch64-darwin also work
  username = "alice";
  host = "personal";
};
```

Set your Git name and email in `hosts/personal.nix` using
`egg.git.userName` and `egg.git.userEmail`. Then activate and start zsh:

```sh
nix run .#install
exec ~/.nix-profile/bin/zsh -l
```

## Moving around

- `c` — fuzzy-pick a directory with a tree preview; `c ~/git` starts in your projects.
- `z name` — jump to a directory you have visited; `zi` opens a history picker.
- `cd -` — go back; `..` / `...` — go up one / two levels.
- **Alt-C** — directory picker; **Ctrl-T** — insert a file path.
- **Tab** — complete paths, then use arrow keys to choose.

Typing a command with a shorter alias shows a quiet tip, for example
`git status --short --branch` → `gs`. Your command still runs normally.
Set `EGG_NO_ALIAS_TIPS=1` in `~/.zshrc.local` to hide tips.

## Everyday commands

```sh
egg help     # discover the tools
egg keys     # keyboard shortcuts
egg fetch    # system dashboard
egg doctor   # check the setup
hms          # apply config changes
```

Cloned elsewhere? Set `egg.directory` in your host config, or export
`EGG_DIR`. Run `nix flake check` to test changes before applying them.

The repository is still named `lazyshell` for now. After renaming or moving it,
set `egg.directory` or `EGG_DIR` to the new checkout path.
