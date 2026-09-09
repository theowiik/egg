# Two rounded pastel badges, with quiet text for transient prompt context.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = (import ../lib/palette.nix { inherit lib; }).hex;
  starship = lib.getExe config.programs.starship.package;
  starshipInit = pkgs.runCommand "egg-starship-init.zsh" { } ''
    ${starship} init zsh --print-full-init > "$out"
  '';
in
{
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkOrder 1000 ''
      if [[ $TERM != dumb ]]; then
        source ${starshipInit}
      fi
    '')
    (lib.mkOrder 1700 (
      lib.replaceStrings
        [ "@clockColor@" "@starship@" "@durationThreshold@" ]
        [ colors.clock starship (toString config.programs.starship.settings.cmd_duration.min_time) ]
        (builtins.readFile ./clock.zsh)
    ))
  ];

  programs.starship = {
    enable = true;
    enableZshIntegration = false;

    settings = {
      add_newline = true;
      command_timeout = 1000;
      palette = "egg";

      palettes.egg = colors;

      # Rounded path and branch badges anchor the prompt; other context stays light.
      format = lib.concatStrings [
        "[🥚 ](fg:text)"
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$git_state"
        "$nix_shell"
        "$cmd_duration"
        "$jobs"
        "$status"
        "$line_break"
        "$character"
      ];

      # The interactive shell renders the cheap modules immediately and fills
      # this literal marker from a single asynchronous Git worker. The text
      # group also delimits it from the preceding $directory variable.
      profiles.egg_fast =
        lib.replaceStrings [ "$git_branch$git_status$git_state" ] [ "[EGG_GIT_CONTEXT](fg:muted)" ]
          config.programs.starship.settings.format;
      profiles.egg_git = "$git_branch$git_status$git_state";

      right_format = "$time";

      username = {
        format = "[$user ](fg:subtle)";
        style_user = "bold";
        style_root = "bold";
        show_always = false;
      };
      hostname = {
        ssh_only = true;
        format = "[@$hostname ](fg:subtle)";
      };

      directory = {
        format = "[](fg:path)[ $path$read_only ](bold bg:path fg:surface)[](fg:path)";
        truncation_length = 5;
        truncation_symbol = "…/";
        truncate_to_repo = false;
        read_only = " ro";
        read_only_style = "bold err";
      };

      git_branch = {
        format = " [](fg:git)[ $branch ](bg:git fg:surface)[](fg:git)";
        style = "fg:git";
      };

      git_status = {
        format = "([ $all_status$ahead_behind](fg:git))";
        style = "fg:git";
        conflicted = "≠\${count}";
        ahead = "↑\${count}";
        behind = "↓\${count}";
        diverged = "↕↑\${ahead_count}↓\${behind_count}";
        untracked = "?\${count}";
        stashed = "\\\$\${count}";
        modified = "!\${count}";
        staged = "+\${count}";
        renamed = "»\${count}";
        deleted = "✘\${count}";
      };

      git_state.format = "[  · ](fg:muted)[$state $progress_current/$progress_total](fg:err)";

      # ❄ marks a `nix develop` / `nix shell` subshell.
      nix_shell = {
        format = "[  · ](fg:muted)[❄ $state](fg:nix)";
        impure_msg = "impure";
        pure_msg = "pure";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[  · ](fg:muted)[$duration](fg:slow)";
      };

      jobs = {
        format = "[  · ](fg:muted)[$number jobs](fg:slow)";
        number_threshold = 1;
        symbol_threshold = 1;
      };

      status = {
        disabled = false;
        format = "[  · ](fg:muted)[exit $status](fg:err)";
      };

      character = {
        success_symbol = "[›](bold brand)";
        error_symbol = "[›](bold err)";
        vimcmd_symbol = "[·](bold git)";
      };

      time = {
        disabled = false;
        format = "[$time](fg:clock)";
        time_format = "%H:%M";
      };
    };
  };
}
