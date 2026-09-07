# eza — a better ls, aliased over `ls`. This is the one standard command
# egg does replace; everything else (cat, du, ps, grep) stays untouched.
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
    # `ls = "eza"` then picks them up, because zsh expands aliases twice.
    enableZshIntegration = false;

    git = true; # show git status per file
    icons = "auto"; # only when the terminal can render them
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--time-style=long-iso"
    ];
  };

  # Only this one alias: `ls` gets eza's icons, git status and header.
  home.shellAliases.ls = "eza";

  programs.zsh.initContent = lib.mkOrder 1600 ''
    # Refresh colors in new shells even when the parent has old session vars.
    export LS_COLORS=${lib.escapeShellArg fileColors}
    export EZA_COLORS=${lib.escapeShellArg fileColors}
  '';
}
