# lazyshell

A Nix-managed shell environment, portable across machines. One repo, one command,
and any Linux or macOS box gets the same zsh, the same tools, and the same aliases.

Built on **Nix flakes** (reproducible, pinned inputs) + **home-manager** (declarative
dotfiles). Nothing here needs root, and nothing touches the system outside `$HOME`.

## What you get

| | |
|---|---|
| **zsh** | history that's shared across terminals, sane options, emacs keybindings, `.zshrc.local` escape hatch |
| **completions** | menu-driven, case-insensitive, cached; picks up `_eza`, `_gh`, `_fd`, `_rg`, … from the packages themselves |
| **eza** | `ls` replacement with git status, icons, and a set of `l`/`ll`/`la`/`lt` aliases |
| **prompt** | starship |
| **navigation** | `fzf` (ctrl-r / ctrl-t / alt-c with previews), `zoxide` (`z foo`), `direnv` |
| **git** | delta diffs, aliases, `gh`, per-directory identity on the work machine |
| **toolbox** | `bat`, `fd`, `ripgrep`, `jq`, `yq`, `btop`, `dust`, `procs`, `tldr`, … |

## Layout

```
flake.nix              inputs (nixpkgs, home-manager) + one entry per machine
home.nix               shared base: session vars, stateVersion, module imports
hosts/
  personal.nix         per-machine settings (identity, extra packages)
  work.nix
modules/
  default.nix          imports every module below
  options.nix          the `lazyshell.*` options hosts set
  packages.nix         the shared CLI toolbox
  zsh.nix              zsh itself: history, options, keybindings
  completions.nix      fpath, compinit caching, completion styles
  aliases.nix          aliases + small shell functions
  eza.nix              eza config and the ls aliases
  git.nix              git, delta, gh
  prompt.nix           starship
  navigation.nix       fzf, zoxide, direnv
```

The split is the point: to change how completions behave you open
`modules/completions.nix` and nothing else.

## Install on a new machine

### 1. Install Nix

```sh
# Linux and macOS. Multi-user install; asks for sudo once.
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Open a new terminal so `nix` is on `$PATH`.

### 2. Enable flakes

Flakes are still gated behind a feature flag:

```sh
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

### 3. Clone the repo

```sh
mkdir -p ~/git && git clone <your-remote>/lazyshell.git ~/git/lazyshell
cd ~/git/lazyshell
```

The path matters only because the `hms` alias assumes `~/git/lazyshell`; change it
in `modules/aliases.nix` if you keep it elsewhere.

### 4. Add an entry for this machine

Find out what to call it and what platform you're on:

```sh
echo "$(whoami)@$(hostname -s)"          # e.g. oet@puter
nix eval --impure --raw --expr builtins.currentSystem   # e.g. x86_64-linux
```

Then add a block to `homeConfigurations` in `flake.nix`:

```nix
"alice@thinkpad" = mkHome {
  system = "x86_64-linux";      # or aarch64-darwin on Apple Silicon
  username = "alice";
  host = "personal";            # which file in hosts/ to use
};
```

`homeDirectory` is derived (`/home/…` on Linux, `/Users/…` on macOS); pass it
explicitly if your setup is unusual.

### 5. Activate

The first time, run home-manager straight from the flake — you don't have it
installed yet:

```sh
nix run home-manager/master -- switch -b backup --flake ~/git/lazyshell#alice@thinkpad
```

`-b backup` renames any dotfile that's in the way (e.g. an existing `~/.zshenv`)
to `*.backup` instead of failing.

After that, `home-manager` is on your `$PATH` and you can use the short form:

```sh
hms          # alias for: home-manager switch --flake ~/git/lazyshell
```

With no `#fragment`, home-manager looks for a `homeConfigurations` entry named
`$USER@$(hostname -f)`, then `$USER@$(hostname)`, then `$USER@$(hostname -s)`,
and finally plain `$USER`. Name your entry to match one of those and `hms` just
works; otherwise append `#user@host` explicitly.

### Try it first, without activating

Activation writes into your real `$HOME`. If you'd rather look before you leap:

```sh
nix run .#try
```

That builds the whole configuration against a throwaway `$HOME`
(`/tmp/lazyshell-try`) and drops you into a zsh running it — aliases,
completions, prompt, plugins and all, with the full toolbox on `$PATH`. Your
own dotfiles are never touched; `exit` and it's gone.

Two things to know about the sandbox: `$HOME` points at the temp directory, so
your ssh keys and credentials aren't visible in there, and it always builds the
`personal` host. It's for kicking the tyres, not for daily use.

`nix develop`, by contrast, is for working *on* this repo — it gives you
`home-manager`, `nixfmt` and `git`, not the shell environment itself.

### 6. Make zsh your login shell

Your zshrc lives at `~/.config/zsh/.zshrc` — home-manager writes a small
`~/.zshenv` that points `ZDOTDIR` there. That works with any zsh binary, so the
simplest option is your system zsh:

```sh
chsh -s "$(command -v zsh)"        # macOS already defaults to zsh
```

To use the Nix-built zsh instead, register it first (it must be listed in
`/etc/shells`):

```sh
command -v zsh | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/zsh"
```

Log out and back in.

## Adding and updating packages

**Add a package everywhere** — edit `modules/packages.nix`, add the attribute name
from nixpkgs to the list, then `hms`:

```nix
home.packages = with pkgs; [
  bat
  fd
  httpie        # <- new
];
```

Search for the right name with `nix search nixpkgs httpie`, or try it before you
commit to it: `nix shell nixpkgs#httpie`.

**Add a package on one machine only** — put it in that host file:

```nix
# hosts/work.nix
lazyshell.extraPackages = with pkgs; [ kubectl awscli2 terraform ];
```

**Add an alias** — `modules/aliases.nix` (or `modules/eza.nix` for `ls`-family ones).

**Configure a program properly** — many tools have a home-manager module that
beats a hand-written dotfile (`programs.neovim`, `programs.tmux`, …). Give it its
own file in `modules/`, then list it in `modules/default.nix`. Browse the options
at <https://nix-community.github.io/home-manager/options.xhtml>, or locally:

```sh
man home-configuration.nix
```

**Update everything to newer versions** — the versions you get are pinned in
`flake.lock`, so nothing moves until you say so:

```sh
nix flake update              # bump nixpkgs + home-manager
nix flake update nixpkgs      # or just one input
hms                           # apply
git commit -am 'flake: update inputs'
```

**Check what changed in home-manager** before switching, if it's been a while:

```sh
hmn      # home-manager news
```

## Syncing between machines

`flake.lock` is what makes this reliable: it pins the exact nixpkgs revision, so
"the same commit" really means "the same binaries" on every machine.

On the machine where you made the change:

```sh
hms                                  # verify it builds and works
git add -A && git commit -m 'zsh: cache the compdump'
git push
```

On the other machine:

```sh
cd ~/git/lazyshell && git pull
hms
```

Nothing else — no bootstrap script, no symlink management.

Notes on keeping the two in sync:

- **Machine-specific things go in `hosts/*.nix`**, never in the shared modules.
  That's what keeps `git pull` conflict-free.
- **Secrets never go in this repo.** Anything sensitive or one-off (work proxies,
  tokens, internal registries) goes in `~/.zshrc.local`, which the config sources
  if it exists and git never sees.
- **Different platforms are fine.** Modules that need to differ branch on
  `pkgs.stdenv.hostPlatform.isDarwin` / `isLinux` — see `modules/packages.nix`.
  Everything else is shared.

### Trying a change without committing to it

```sh
home-manager build --flake ~/git/lazyshell      # build only, no activation
nix flake check                                 # evaluate everything
```

### Rolling back

Every activation is a generation, and the old ones are still on disk:

```sh
home-manager generations                        # list them
/nix/store/…-home-manager-generation/activate    # re-activate an older one
```

To reclaim disk space later: `home-manager expire-generations '-30 days'` and
`nix-collect-garbage -d` (aliased to `ngc`).

## Development shell

```sh
nix develop      # home-manager, nixfmt and git, without installing them
nix fmt          # format every .nix file
nix run .#try    # sandbox shell running the config (see above)
```

`direnv allow` in the repo does the same automatically on `cd`.
