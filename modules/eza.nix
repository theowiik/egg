# eza — the ls replacement, plus the aliases that make it the default.
{ lib, pkgs, ... }:
let
  colors = (import ../lib/palette.nix { inherit lib; }).ansi;
  fileColors = "di=1;${colors.dir}:ln=${colors.nix}:ex=${colors.git}:or=${colors.err}";
in
{
  home.sessionVariables = {
    LS_COLORS = fileColors;
    EZA_COLORS = fileColors;
  };

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
    # Refresh colors in new shells even when the parent has old session vars.
    export LS_COLORS=${lib.escapeShellArg fileColors}
    export EZA_COLORS=${lib.escapeShellArg fileColors}
    autoload -Uz add-zsh-hook
    _egg_list_directory() {
      # Keep command substitutions, scripts and redirected commands quiet.
      # Set EGG_NO_AUTO_LS=1 in ~/.zshrc.local to disable automatic listings.
      [[ -o interactive && -t 1 && $ZSH_SUBSHELL -eq 0 && -z "''${EGG_NO_AUTO_LS:-}" ]] || return 0
      ${pkgs.eza}/bin/eza --grid --group-directories-first --icons=auto --color=auto || true
    }
    add-zsh-hook chpwd _egg_list_directory
  '';
}
