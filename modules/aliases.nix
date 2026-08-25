# Aliases and small shell functions.
# eza-based ls aliases live next to the eza config in modules/eza.nix.
{ lib, pkgs, ... }:
{
  home.shellAliases = {
    # --- safety nets ---
    cp = "cp -i";
    mv = "mv -i";
    rm = "rm -i";

    # --- navigation ---
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";

    # --- modern replacements ---
    cat = "bat --paging=never";
    du = "dust";
    ps = "procs";
    top = "btop";
    grep = "grep --color=auto";

    # --- git (the long ones; git's own aliases are in modules/git.nix) ---
    g = "git";
    gs = "git status --short --branch";
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gd = "git diff";
    gl = "git log --oneline --graph --decorate -20";
    gp = "git push";
    gpl = "git pull --rebase";

    # --- nix / lazyshell ---
    hms = "home-manager switch --flake ~/git/lazyshell";
    hmn = "home-manager news --flake ~/git/lazyshell";
    nsh = "nix shell nixpkgs#";
    nrun = "nix run nixpkgs#";
    ngc = "nix-collect-garbage -d";
  };

  programs.zsh.initContent = lib.mkOrder 1000 ''
    # --- functions --------------------------------------------------------

    # mkcd <dir> — create a directory and step into it.
    mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

    # up [n] — climb n directories (default 1).
    up() {
      local n=''${1:-1}
      local path=""
      for _ in $(seq "$n"); do path="../$path"; done
      cd "$path" || return
    }

    # ff <pattern> — fuzzy-open a file match in $EDITOR.
    ff() {
      local file
      file=$(fd --type f --hidden --exclude .git "''${1:-}" | fzf --select-1 --exit-0) || return
      [[ -n "$file" ]] && ''${EDITOR:-vi} "$file"
    }
  '';
}
