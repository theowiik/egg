# The root doubles as an atomic lock. Never delete a directory we did not create.
preview_root="@previewRoot@"
if ! mkdir -m 700 -- "$preview_root"; then
  printf 'lazyshell: preview already running or directory exists: %s\n' "$preview_root" >&2
  printf 'Close the other preview. If it crashed, remove that directory before retrying.\n' >&2
  exit 1
fi
trap 'rm -rf -- "$preview_root"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

preview_home="$preview_root/home"
mkdir -p "$preview_home" "$preview_root/tmp"
cp -rL --no-preserve=mode "@homeFiles@/." "$preview_home/"
chmod -R u+w "$preview_home"
ln -s "@profile@" "$preview_home/.nix-profile"
repository="${LAZYSHELL_DIR:-$PWD}"

printf 'lazyshell preview — temporary home, removed on exit.\n'
printf 'Commands still have normal access to your files. Type exit to leave.\n\n'
cd "$preview_home"

# Start with a clean environment so inherited ZDOTDIR, XDG paths, Git config,
# Home Manager guards and tool-specific settings cannot select the real home.
env -i \
  HOME="$preview_home" \
  PWD="$preview_home" \
  ZDOTDIR="$preview_home/.config/zsh" \
  XDG_CONFIG_HOME="$preview_home/.config" \
  XDG_DATA_HOME="$preview_home/.local/share" \
  XDG_STATE_HOME="$preview_home/.local/state" \
  XDG_CACHE_HOME="$preview_home/.cache" \
  TMPDIR="$preview_root/tmp" \
  PATH="@profile@/bin:$PATH" \
  NIX_PROFILES="@profile@" \
  SHELL="@zsh@" \
  USER="$(id -un)" LOGNAME="$(id -un)" \
  TERM="${TERM:-dumb}" COLORTERM="${COLORTERM:-}" LANG="${LANG:-en_US.UTF-8}" \
  LAZYSHELL_DIR="$repository" LAZYSHELL_PREVIEW=1 \
  LAZYSHELL_NO_WELCOME="${LAZYSHELL_NO_WELCOME:-}" \
  "@zsh@" -l "$@"
