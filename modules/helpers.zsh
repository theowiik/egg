# Shell helpers are also exercised by the flake smoke check.
mkcd() {
  if (( $# != 1 )); then
    print -u2 'usage: mkcd <directory>'
    return 2
  fi
  mkdir -p -- "$1" && builtin cd -- "$1"
}

ff() {
  local selected
  IFS= read -r -d $'\0' selected < <(
    fd --type f --hidden --exclude .git --print0 -- "${1:-}" |
      fzf --read0 --print0 --select-1 --exit-0
  ) || return
  [[ -n $selected ]] && ${=EDITOR:-vi} -- "$selected"
}

# Search below a directory (the current one by default); preserve unusual names.
c() {
  (( $# <= 1 )) || { print -u2 'usage: c [directory]'; return 2; }
  local selected
  IFS= read -r -d $'\0' selected < <(
    fd --type d --hidden --exclude .git --print0 . "${1:-.}" |
      fzf --read0 --print0 --prompt='directory · ' \
        --header='Enter: open directory · Esc: cancel' \
        --preview='eza --tree --level=2 --color=always -- {}'
  ) || return
  [[ -n $selected ]] && builtin cd -- "$selected"
}
