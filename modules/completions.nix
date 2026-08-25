# Completion behaviour: where definitions come from, and how the menu looks.
#
# Packages install their own completions into $out/share/zsh/site-functions;
# home-manager symlinks those into the profile, so putting the profile on
# $fpath picks up eza, gh, delta, … for free. git's `_git` ships with zsh.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zsh = {
    initContent = lib.mkMerge [
      # Runs before compinit — fpath has to be complete by then.
      (lib.mkOrder 550 ''
        fpath=(
          ${config.home.profileDirectory}/share/zsh/site-functions
          ${pkgs.zsh-completions}/share/zsh/site-functions
          $fpath
        )
      '')

      # Runs after compinit — zstyles are read lazily at completion time.
      (lib.mkOrder 1000 ''
        # --- completion styles --------------------------------------------
        zstyle ':completion:*' menu select                      # arrow-key menu
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS} # colourise matches
        zstyle ':completion:*' group-name ""                    # group by category
        zstyle ':completion:*:descriptions' format '%F{blue}%B%d%b%f'
        zstyle ':completion:*:warnings' format '%F{red}no matches%f'
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/zcompcache"
        zstyle ':completion:*' special-dirs true                # complete ../
        zstyle ':completion:*:*:kill:*:processes' command 'ps -u $USER -o pid,cmd -w'

        # Don't offer a file that is already on the line (e.g. `mv a <tab>`).
        zstyle ':completion:*:(rm|mv|cp|diff):*' ignore-line other
      '')
    ];

    # Cache the compdump under XDG and do the expensive full rebuild at most
    # once a day; the rest of the time reuse the dump. Keeps startup snappy.
    completionInit = ''
      autoload -Uz compinit
      _zcompdump="${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
      mkdir -p "''${_zcompdump:h}"
      # Glob qualifiers only expand in an assignment here, not inside [[ ]].
      _zcompstale=( "$_zcompdump"(N.mh+24) )
      if (( $#_zcompstale )) || [[ ! -f "$_zcompdump" ]]; then
        compinit -d "$_zcompdump"
      else
        compinit -C -d "$_zcompdump"
      fi
      unset _zcompdump _zcompstale
    '';
  };
}
