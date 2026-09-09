# Render the cheap prompt synchronously; Git runs in one coalescing worker.
# Clock redraws and empty Enter presses reuse the rendered prompt.
if [[ -o interactive && -t 0 && -t 1 && ${TERM:-dumb} != dumb ]]; then
  zmodload zsh/sched
  autoload -Uz add-zsh-hook add-zle-hook-widget

  # Re-sourcing .zshrc must not capture our already-cached prompt as a template.
  if [[ $PROMPT != '${_egg_clock_left}' ]]; then
    typeset -g _egg_clock_template=${PROMPT/ prompt / prompt --profile=egg_fast }
  fi
  typeset -g _egg_git_context=${_egg_git_context:-}
  typeset -gi _egg_git_generation=${_egg_git_generation:-0}

  _egg_git_render() {
    @starship@ prompt --profile=egg_git --terminal-width="$COLUMNS"
  }

  _egg_prompt_compose() {
    # Parameter expansion is not recursive: paths and branch names stay data,
    # including strings containing dollars, backticks or prompt escapes.
    # Use the final marker so a directory named EGG_GIT_CONTEXT is literal.
    _egg_clock_left=${_egg_clock_base%EGG_GIT_CONTEXT*}${_egg_git_context}${_egg_clock_base##*EGG_GIT_CONTEXT}
  }

  _egg_git_start() {
    # One worker per shell. Commands arriving during a scan invalidate its
    # generation; the callback starts one fresh scan instead of queuing work.
    (( ${+_egg_git_fd} )) && return 0
    _egg_git_worker_generation=$_egg_git_generation
    exec {_egg_git_fd}< <(_egg_git_render; printf '\0')
    zle -F "$_egg_git_fd" _egg_git_ready
  }

  _egg_git_ready() {
    local result
    IFS= read -r -d '' -u "$1" result
    zle -F "$1"
    exec {_egg_git_fd}<&-
    unset _egg_git_fd
    if [[ $_egg_git_worker_generation = $_egg_git_generation ]]; then
      # add_newline applies to Starship profiles too; Git belongs inline.
      _egg_git_context=${result#$'\n'}
      _egg_prompt_compose
      zle .reset-prompt
    else
      _egg_git_start
    fi
  }

  _egg_prompt_preexec() {
    (( ++_egg_git_generation ))
    _egg_prompt_command_ran=1
  }

  _egg_clock_cache() {
    if [[ ${_egg_prompt_directory-} != $PWD ]]; then
      _egg_prompt_directory=$PWD
      _egg_git_context=''
      (( ++_egg_git_generation ))
      _egg_prompt_command_ran=1
    fi
    # Starship drops command metadata on empty Enter. Normalize fields that
    # render identically so a successful, short command doesn't force a redraw.
    local duration=${STARSHIP_DURATION:-0}
    (( duration < @durationThreshold@ )) && duration=0
    local signature="$PWD:$COLUMNS:${KEYMAP:-}:${STARSHIP_CMD_STATUS:-0}:${STARSHIP_PIPE_STATUS[*]:-0}:$duration:$STARSHIP_JOBS_COUNT"
    if [[ ${_egg_prompt_signature-} != $signature || ${_egg_prompt_command_ran:-0} = 1 ]]; then
      _egg_clock_base=${(e)_egg_clock_template}
      _egg_prompt_signature=$signature
    fi
    if [[ ${_egg_prompt_command_ran:-0} = 1 ]]; then
      _egg_git_start
      _egg_prompt_command_ran=0
    fi
    typeset -g _egg_clock_columns=$COLUMNS
    _egg_prompt_compose
    PROMPT='${_egg_clock_left}'
    RPROMPT='%F{@clockColor@}%D{%H:%M:%S}%f '
    # Opting out freezes the time for this prompt, without disabling fast Git.
    if [[ -n ${EGG_NO_LIVE_CLOCK:-} ]]; then
      RPROMPT=${(%)RPROMPT}
    fi
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
    [[ -n ${EGG_NO_LIVE_CLOCK:-} ]] || sched +1 _egg_clock_tick
    return 0
  }

  _egg_clock_keymap() {
    _egg_clock_cache
    zle .reset-prompt
  }

  # Starship captures exit status/duration first; our hook then builds the UI.
  add-zsh-hook precmd _egg_clock_cache
  add-zsh-hook preexec _egg_prompt_preexec
  add-zle-hook-widget line-init _egg_clock_start
  add-zle-hook-widget line-finish _egg_clock_stop
  add-zle-hook-widget keymap-select _egg_clock_keymap
fi
