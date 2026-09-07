# Aliases. Deliberately few: the conventional git shorthands, egg's own
# maintenance commands, and `ls` over in modules/eza.nix. Nothing else
# shadows a standard command, so `cat`, `du`, `ps` and `grep` are real.
{ ... }:
{
  home.shellAliases = {
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

    # --- egg ---
    hms = "egg switch";
    hmn = "egg news";
  };
}
