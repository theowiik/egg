if [[ "${1:-}" = --help || "${1:-}" = -h ]]; then
  echo 'Usage: nix run .#install -- [--build | --news] [Home Manager options]'
  echo 'Default: switch. --build builds without activating; --news shows news.'
  echo 'Repository: EGG_DIR or current directory. Settings: EGG_CONFIG or XDG_CONFIG_HOME/egg/local.nix.'
  exit 0
fi
dir="${EGG_DIR:-$PWD}"
if [ ! -f "$dir/flake.nix" ]; then
  echo "egg: no flake.nix in $dir; run from the repository or set EGG_DIR" >&2
  exit 1
fi
export EGG_DIR
EGG_DIR=$(cd "$dir" && pwd -P)
export EGG_SYSTEM='@system@'
export EGG_USERNAME
EGG_USERNAME=$(id -un)
export EGG_HOME="${HOME:?egg: HOME must be set}"
export EGG_CONFIG="${EGG_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/egg/local.nix}"
if [[ "$EGG_HOME" != /* || "$EGG_CONFIG" != /* ]]; then
  echo 'egg: HOME and EGG_CONFIG (or XDG_CONFIG_HOME) must be absolute paths' >&2
  exit 1
fi
if [ -e "$EGG_CONFIG" ] && [ ! -f "$EGG_CONFIG" ]; then
  echo "egg: local configuration is not a file: $EGG_CONFIG" >&2
  exit 1
fi
if [ ! -f "$EGG_CONFIG" ]; then
  echo "egg: no local settings at $EGG_CONFIG; Git identity will be unset." >&2
  echo "Copy $EGG_DIR/local.nix.example there and set your identity, then rebuild." >&2
fi
action=switch
case "${1:-}" in
  --build) action=build; shift ;;
  --news) action=news; shift ;;
esac
exec home-manager "$action" -b backup --impure --flake "$EGG_DIR#current" "$@"
