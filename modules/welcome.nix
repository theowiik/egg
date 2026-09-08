# A one-off banner in interactive login shells. Shell builtins only: no
# subprocesses, no hardware probing, nothing that delays the first prompt.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = (import ../lib/palette.nix { inherit lib; }).ansi;
  platform = if pkgs.stdenv.hostPlatform.isDarwin then "macOS" else "Linux";
in
{
  options.egg.welcome.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Show a short console welcome in interactive login shells.";
  };

  config.programs.zsh.initContent = lib.mkIf config.egg.welcome.enable (
    lib.mkOrder 1500 ''
      # Login shells only; avoid noise in scripts, nested shells and dumb terminals.
      # Set EGG_NO_WELCOME=1 in ~/.zshrc.local to opt out immediately.
      if [[ -o interactive && -o login && -t 1 && "''${TERM:-dumb}" != dumb && -z "''${EGG_NO_WELCOME:-}" ]]; then
        print
        printf '\033[1;${colors.brand}m  🥚 egg\033[0m\n'
        printf '\033[${colors.subtle}m  %s\033[0m\n' '${platform} · ${toString (builtins.length config.egg.toolbox)} tools'
        printf '\033[${colors.muted}m  → \033[${colors.dir}megg help\033[0m\n'
        print
      fi
    ''
  );
}
