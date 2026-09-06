# eza — the ls replacement, plus the aliases that make it the default.
{ lib, pkgs, ... }:
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

  programs.zsh.initContent = lib.mkOrder 1600 ''
    autoload -Uz add-zsh-hook
    _lazyshell_list_directory() {
      # Keep command substitutions, scripts and redirected commands quiet.
      # Set LAZYSHELL_NO_AUTO_LS=1 in ~/.zshrc.local to disable automatic listings.
      [[ -o interactive && -t 1 && $ZSH_SUBSHELL -eq 0 && -z "''${LAZYSHELL_NO_AUTO_LS:-}" ]] || return 0
      ${pkgs.eza}/bin/eza --grid --group-directories-first --icons=auto --color=auto || true
    }
    add-zsh-hook chpwd _lazyshell_list_directory
  '';
}
