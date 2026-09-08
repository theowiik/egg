# 🥚 egg

A portable zsh environment managed by Nix Home Manager. A prompt, fuzzy finding,
and a small toolbox for Linux and Apple Silicon macOS.

## Try it

Install [Nix](https://nixos.org/download/), then:

```sh
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
git clone https://github.com/theowiik/egg.git ~/git/egg
cd ~/git/egg
nix run .#try
```

Opens a temporary home without changing your dotfiles. Type `exit` to clean up.

## Install

```sh
cp configs/example.nix configs/personal.nix
```

Edit `configs/personal.nix` with your Git name and email, then:

```sh
nix run .#install -- --config personal
exec ~/.nix-profile/bin/zsh -l
```

Use any filename in `configs/` and select it with `--config <name>`.
`puter` and `neo` are already configured for Theo. Username, home directory,
and platform are detected automatically. Add `--build` to build without installing.

Your settings go in `configs/<name>.nix`; shared settings live in `modules/`.
New config files are Git-ignored, so updates leave them alone. The example,
`puter.nix`, and `neo.nix` are tracked.

## Use and update

| Command | Purpose |
|---|---|
| `egg help` | Available tools |
| `egg aliases` / `egg keys` | Shortcuts |
| `egg doctor` | Check your setup |
| `egg edit` | Open the repo |
| `hms` | Rebuild using your selected config |

From the repo, pull shared changes and apply them:

```sh
git pull
hms
```

For development: `nix flake check` runs tests; `nix fmt` formats Nix files.
