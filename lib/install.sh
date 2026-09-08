action=switch
config_name=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --config)
      if [[ ! "${2:-}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo 'egg: --config needs a name using letters, numbers, underscores or hyphens (without .nix)' >&2
        exit 1
      fi
      config_name="$2"
      shift 2
      ;;
    --build) action=build; shift ;;
    --news) action=news; shift ;;
    --help | -h)
      echo 'Usage: nix run .#install -- [--config NAME] [--build | --news] [Home Manager options]'
      echo 'Settings: configs/NAME.nix in the repository; defaults to configs/personal.nix.'
      echo 'Rebuilds remember the chosen file. EGG_CONFIG can override its absolute path.'
      echo 'Default: switch. --build builds without activating; --news shows news.'
      exit 0
      ;;
    *) break ;;
  esac
done
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
export EGG_CONFIG="${EGG_CONFIG:-$EGG_DIR/configs/personal.nix}"
if [ -n "$config_name" ]; then
  EGG_CONFIG="$EGG_DIR/configs/$config_name.nix"
  if [ ! -f "$EGG_CONFIG" ]; then
    echo "egg: config not found: $EGG_CONFIG; copy configs/example.nix and edit it first" >&2
    exit 1
  fi
fi
if [[ "$EGG_HOME" != /* || "$EGG_CONFIG" != /* ]]; then
  echo 'egg: HOME and EGG_CONFIG must be absolute paths' >&2
  exit 1
fi
if [ -e "$EGG_CONFIG" ] && [ ! -f "$EGG_CONFIG" ]; then
  echo "egg: local configuration is not a file: $EGG_CONFIG" >&2
  exit 1
fi
if [ ! -f "$EGG_CONFIG" ]; then
  echo "egg: no local settings at $EGG_CONFIG; Git identity will be unset." >&2
  echo "Copy $EGG_DIR/configs/example.nix there and set your identity, then rebuild." >&2
fi
exec home-manager "$action" -b backup --impure --flake "$EGG_DIR#current" "$@"
