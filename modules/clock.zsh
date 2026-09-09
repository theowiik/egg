# Starship renders once per prompt; zsh expands and refreshes the live clock.
# No background processes, SIGALRM trap or changes to the user's idle timeout.
# Set EGG_NO_LIVE_CLOCK=1 in ~/.zshrc.local to keep the static clock.
if [[ -o interactive && -t 0 && -t 1 && ${TERM:-dumb} != dumb && -z ${EGG_NO_LIVE_CLOCK:-} ]]; then
  zmodload zsh/sched
  autoload -Uz add-zsh-hook add-zle-hook-widget

  # Save the trusted Starship template, including its command substitution.
  # Preserve it when .zshrc is sourced again with our cached prompt active.
  if [[ $PROMPT != '${_egg_clock_left}' ]]; then
    typeset -g _egg_clock_template=$PROMPT
  fi

  _egg_clock_cache() {
    typeset -g _egg_clock_left=${(e)_egg_clock_template}
    typeset -g _egg_clock_columns=$COLUMNS
    # Parameter expansion is not evaluated recursively: filenames containing
    # shell syntax remain text, just as in Starship's original prompt.
    PROMPT='${_egg_clock_left}'
    RPROMPT='%F{@clockBackground@}%S%s%f%K{@clockBackground@}%F{@clockForeground@} %D{%H:%M:%S} %f%k%F{@clockBackground@}%f '
  }

  _egg_clock_stop() {
    local event
    for (( event = ${#zsh_scheduled_events}; event > 0; event-- )); do
      if [[ ${zsh_scheduled_events[event]} == *:_egg_clock_tick ]]; then
        sched -$event
      fi
    done
    return 0
  }

  _egg_clock_tick() {
    local previous_status=$?
    if zle; then
      [[ $COLUMNS = $_egg_clock_columns ]] || _egg_clock_cache
      zle .reset-prompt
      sched +1 _egg_clock_tick
    fi
    return $previous_status
  }

  _egg_clock_start() {
    _egg_clock_stop
    sched +1 _egg_clock_tick
  }

  _egg_clock_keymap() {
    _egg_clock_cache
    zle .reset-prompt
  }

  # Registered after Starship so its exit status, duration and jobs are ready.
  add-zsh-hook precmd _egg_clock_cache
  add-zle-hook-widget line-init _egg_clock_start
  add-zle-hook-widget line-finish _egg_clock_stop
  add-zle-hook-widget keymap-select _egg_clock_keymap
fi
