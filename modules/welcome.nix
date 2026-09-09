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
    lib.mkOrder 1800 ''
      # Login shells only; avoid noise in scripts, nested shells and dumb terminals.
      # Set EGG_NO_WELCOME=1 in ~/.zshrc.local to opt out immediately.
      if [[ -o interactive && -o login && -t 1 && "''${TERM:-dumb}" != dumb && -z "''${EGG_NO_WELCOME:-}" ]]; then
        # Emit the banner once the first prompt is ready, in a single write.
        # This avoids showing the welcome and then pausing before the cursor.
        autoload -Uz add-zsh-hook
        _egg_welcome_once() {
          printf '\n\033[1;${colors.brand}m  🥚 egg\033[0m\n\033[${colors.subtle}m  %s\033[0m\n\033[${colors.muted}m  → \033[${colors.dir}megg help\033[0m\n\n' '${platform} · ${toString (builtins.length config.egg.toolbox)} tools'
          add-zsh-hook -d precmd _egg_welcome_once
          unfunction _egg_welcome_once
        }
        add-zsh-hook precmd _egg_welcome_once
      fi
    ''
  );
}
