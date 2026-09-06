# Shell helpers are also exercised by the flake smoke check.
mkcd() {
  if (( $# != 1 )); then
    print -u2 'usage: mkcd <directory>'
    return 2
  fi
  mkdir -p -- "$1" && builtin cd -- "$1"
}

up() {
  local levels=${1:-1} destination=. i
  if (( $# > 1 )) || [[ $levels != <-> || ${#levels} -gt 4 ]]; then
    print -u2 'usage: up [non-negative integer, at most 9999]'
    return 2
  fi
  for (( i = 0; i < 10#$levels; i++ )); do
    destination+=/..
  done
  builtin cd -- "$destination"
}

ff() {
  local selected
  IFS= read -r -d $'\0' selected < <(
    fd --type f --hidden --exclude .git --print0 -- "${1:-}" |
      fzf --read0 --print0 --select-1 --exit-0
  ) || return
  [[ -n $selected ]] && ${=EDITOR:-vi} -- "$selected"
}

# A function keeps the package name attached to the flake reference.
nsh() {
  (( $# )) || { print -u2 'usage: nsh <package> [nix flags]'; return 2; }
  local package=$1
  shift
  nix shell "nixpkgs#$package" "$@"
}

nrun() {
  (( $# )) || { print -u2 'usage: nrun <package> [nix flags / -- arguments]'; return 2; }
  local package=$1
  shift
  nix run "nixpkgs#$package" "$@"
}
