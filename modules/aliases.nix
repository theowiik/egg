# Aliases and small shell functions.
# eza-based ls aliases live next to the eza config in modules/eza.nix.
{ lib, ... }:
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
    hms = "lazyshell switch";
    hmn = "lazyshell news";
    ngc = "nix-collect-garbage -d";
  };

  programs.zsh.initContent = lib.mkOrder 1000 (builtins.readFile ./helpers.zsh);
}
