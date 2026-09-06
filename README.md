# lazyshell

A ready-to-use zsh setup with a polished prompt, system dashboard, and useful
terminal tools. For Linux and Apple Silicon macOS.

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
`lazyshell.git.userName` and `lazyshell.git.userEmail`. Then activate and start zsh:

```sh
nix run .#install
exec ~/.nix-profile/bin/zsh -l
```

## Everyday commands

```sh
lazyshell help     # discover the tools
lazyshell keys     # keyboard shortcuts
lazyshell fetch    # system dashboard
lazyshell doctor   # check the setup
hms               # apply config changes
```

Cloned elsewhere? Set `lazyshell.directory` in your host config, or export
`LAZYSHELL_DIR`. Run `nix flake check` to test changes before applying them.
