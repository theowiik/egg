# Powerline prompt: a peach path, mint Git context, and tangerine accents.
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

      # Segments that always render (egg → directory) are chained with powerline
      # separators; the optional context blocks are self-closing islands so an
      # absent segment never leaves an empty colored wedge behind. Inverted
      # opening arrows cut a right-facing notch using the terminal background.
      format = lib.concatStrings [
        "[](fg:frame inverted)"
        "[🥚 ](bg:frame fg:text)"
        "$username"
        "$hostname"
        "[](fg:frame bg:path)"
        "$directory"
        "[](fg:path)"
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
      # this literal marker from a single asynchronous Git worker.
      profiles.egg_fast =
        lib.replaceStrings [ "$git_branch$git_status$git_state" ] [ "EGG_GIT_CONTEXT" ]
          config.programs.starship.settings.format;
      profiles.egg_git = "$git_branch$git_status$git_state";

      right_format = "$time";

      username = {
        format = "[ $user ](bg:frame fg:text)";
        style_user = "bold";
        style_root = "bold";
        show_always = false;
      };
      hostname = {
        ssh_only = true;
        format = "[@$hostname ](bg:frame fg:text)";
      };

      directory = {
        format = "[ $path$read_only ](bg:path fg:surface)";
        truncation_length = 5;
        truncation_symbol = "…/";
        truncate_to_repo = false;
        read_only = " ro";
        read_only_style = "bold err";
      };

      git_branch = {
        format = "[](fg:git inverted)[  $branch](bg:git fg:surface)";
        style = "bg:git fg:surface";
      };

      git_status = {
        format = "([ $all_status$ahead_behind](bg:git fg:surface))[](fg:git)";
        style = "bg:git fg:surface";
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

      git_state.format = "[](fg:err inverted)[ $state $progress_current/$progress_total ](bg:err fg:surface)[](fg:err)";

      # ❄ marks a `nix develop` / `nix shell` subshell.
      nix_shell = {
        format = "[](fg:nix inverted)[ ❄ $state ](bg:nix fg:surface)[](fg:nix)";
        impure_msg = "impure";
        pure_msg = "pure";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[](fg:slow inverted)[ $duration ](bg:slow fg:surface)[](fg:slow)";
      };

      jobs = {
        format = "[](fg:slow inverted)[ $number jobs ](bg:slow fg:surface)[](fg:slow)";
        number_threshold = 1;
        symbol_threshold = 1;
      };

      status = {
        disabled = false;
        format = "[](fg:err inverted)[ exit $status ](bg:err fg:surface)[](fg:err)";
      };

      character = {
        success_symbol = "[❯](bold brand)";
        error_symbol = "[❯](bold err)";
        vimcmd_symbol = "[❮](bold git)";
      };

      time = {
        disabled = false;
        format = "[$time](fg:clock)";
        time_format = "%H:%M";
      };
    };
  };
}
