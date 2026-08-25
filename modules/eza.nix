# eza — the ls replacement, plus the aliases that make it the default.
{ ... }:
{
  programs.eza = {
    enable = true;
    enableZshIntegration = false; # we define our own aliases below

    git = true; # show git status per file
    icons = "auto"; # only when the terminal can render them
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--time-style=long-iso"
    ];
  };

  home.shellAliases = {
    ls = "eza";
    l = "eza --long --git";
    ll = "eza --long --all --git";
    la = "eza --long --all --git --group";
    lt = "eza --tree --level=2";
    ltt = "eza --tree --level=3 --long";
    lsize = "eza --long --sort=size --reverse";
    lmod = "eza --long --sort=modified --reverse";
  };
}
