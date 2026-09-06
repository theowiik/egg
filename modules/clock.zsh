# Starship renders once per prompt; zsh expands and refreshes the live clock.
# No background processes, SIGALRM trap or changes to the user's idle timeout.
# Set LAZYSHELL_NO_LIVE_CLOCK=1 in ~/.zshrc.local to keep the static clock.
if [[ -o interactive && -t 0 && -t 1 && ${TERM:-dumb} != dumb && -z ${LAZYSHELL_NO_LIVE_CLOCK:-} ]]; then
  zmodload zsh/sched
  autoload -Uz add-zsh-hook add-zle-hook-widget

  # Save the trusted Starship template, including its command substitution.
  # Preserve it when .zshrc is sourced again with our cached prompt active.
  if [[ $PROMPT != '${_lazyshell_clock_left}' ]]; then
    typeset -g _lazyshell_clock_template=$PROMPT
  fi

  _lazyshell_clock_cache() {
    typeset -g _lazyshell_clock_left=${(e)_lazyshell_clock_template}
    typeset -g _lazyshell_clock_columns=$COLUMNS
    # Parameter expansion is not evaluated recursively: filenames containing
    # shell syntax remain text, just as in Starship's original prompt.
    PROMPT='${_lazyshell_clock_left}'
    RPROMPT='%F{@clockColor@}%D{%H:%M:%S}%f '
  }

  _lazyshell_clock_stop() {
    local event
    for (( event = ${#zsh_scheduled_events}; event > 0; event-- )); do
      if [[ ${zsh_scheduled_events[event]} == *:_lazyshell_clock_tick ]]; then
        sched -$event
      fi
    done
    return 0
  }

  _lazyshell_clock_tick() {
    if zle; then
      [[ $COLUMNS = $_lazyshell_clock_columns ]] || _lazyshell_clock_cache
      zle .reset-prompt
      sched +1 _lazyshell_clock_tick
    fi
    return 0
  }

  _lazyshell_clock_start() {
    _lazyshell_clock_stop
    sched +1 _lazyshell_clock_tick
  }

  _lazyshell_clock_keymap() {
    _lazyshell_clock_cache
    zle .reset-prompt
  }

  # Registered after Starship so its exit status, duration and jobs are ready.
  add-zsh-hook precmd _lazyshell_clock_cache
  add-zle-hook-widget line-init _lazyshell_clock_start
  add-zle-hook-widget line-finish _lazyshell_clock_stop
  add-zle-hook-widget keymap-select _lazyshell_clock_keymap
fi
