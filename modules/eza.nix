# eza — the ls replacement, plus the aliases that make it the default.
{ ... }:
{
  programs.eza = {
    enable = true;
    # false only suppresses home-manager's own ls/ll/la/lt set — the
    # `eza = "eza <options>"` alias below it is emitted either way, and that
    # is what makes our `ls` inherit the options via alias expansion.
    enableZshIntegration = false;

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
