# eza — a better ls, invoked as `eza`. Deliberately not aliased over `ls`:
# the real ls stays the real ls.
{ lib, ... }:
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
    # home-manager's own ls/ll/la/lt aliases stay off; the `eza = "eza
    # <options>"` alias it emits regardless is what carries the options below.
    enableZshIntegration = false;

    git = true; # show git status per file
    icons = "auto"; # only when the terminal can render them
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--time-style=long-iso"
    ];
  };

  programs.zsh.initContent = lib.mkOrder 1600 ''
    # Refresh colors in new shells even when the parent has old session vars.
    export LS_COLORS=${lib.escapeShellArg fileColors}
    export EZA_COLORS=${lib.escapeShellArg fileColors}
  '';
}
