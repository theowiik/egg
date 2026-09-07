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

# Search below a directory (the current one by default); preserve unusual names.
c() {
  (( $# <= 1 )) || { print -u2 'usage: c [directory]'; return 2; }
  local selected
  IFS= read -r -d $'\0' selected < <(
    fd --type d --hidden --exclude .git --print0 . "${1:-.}" |
      fzf --read0 --print0 --prompt='JUMP ❯ ' \
        --header='Enter: open directory · Esc: cancel' \
        --preview='eza --tree --level=2 --color=always -- {}'
  ) || return
  [[ -n $selected ]] && builtin cd -- "$selected"
}

# Suggest the shortest literal prefix alias without evaluating user input.
# preexec receives the original line, before aliases expand.
_egg_alias_tip() {
  [[ -o interactive && -t 2 && -z ${EGG_NO_ALIAS_TIPS:-} ]] || return 0
  local line=$1 name expansion candidate best=''
  # Leading whitespace is also the opt-out for private history entries.
  [[ $line == [[:space:]]* ]] && return 0
  for name in ${(ok)aliases}; do
    expansion=$aliases[$name]
    [[ -n $expansion && $expansion != *$'\n'* ]] || continue
    if [[ $line == "$expansion" || $line == "$expansion "* ]]; then
      candidate="$name${line#$expansion}"
      if (( ${#candidate} < ${#line} )) && { [[ -z $best ]] || (( ${#candidate} < ${#best} )); }; then
        best=$candidate
      fi
    fi
  done
  if [[ -n $best ]]; then
    # Only show the alias, never repeat arguments that may contain secrets.
    name=${best%% *}
    print -u2 -P -- "%F{@tipColor@}  tip%f %F{@mutedColor@}use%f %F{@tipColor@}${name//\%/%%}%f %F{@mutedColor@}for%f ${aliases[$name]//\%/%%}"
  fi
  return 0
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _egg_alias_tip
