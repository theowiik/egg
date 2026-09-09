# Powerline prompt: an egg, a lavender path, and mint Git context on filled segments.
{ lib, ... }:
let
  colors = (import ../lib/palette.nix { inherit lib; }).hex;
in
{
  programs.zsh.initContent = lib.mkOrder 1700 (
    lib.replaceStrings [ "@clockColor@" ] [ colors.cyan ] (builtins.readFile ./clock.zsh)
  );

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

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
        "[](fg:brand inverted)"
        "[🥚 ](bg:brand fg:surface)"
        "$username"
        "$hostname"
        "[](fg:brand bg:nix)"
        "$directory"
        "[](fg:nix)"
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

      right_format = "$time";

      username = {
        format = "[ $user ](bg:brand fg:surface)";
        style_user = "bold";
        style_root = "bold";
        show_always = false;
      };
      hostname = {
        ssh_only = true;
        format = "[@$hostname ](bg:brand fg:surface)";
      };

      directory = {
        format = "[ $path$read_only ](bg:nix fg:text)";
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

      git_state.format = "[](fg:err inverted)[ $state $progress_current/$progress_total ](bg:err fg:text)[](fg:err)";

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
        format = "[](fg:err inverted)[ exit $status ](bg:err fg:text)[](fg:err)";
      };

      character = {
        success_symbol = "[❯](bold pink)";
        error_symbol = "[❯](bold err)";
        vimcmd_symbol = "[❮](bold git)";
      };

      time = {
        disabled = false;
        format = "[](fg:overlay inverted)[  $time ](bg:overlay fg:subtle)";
        time_format = "%H:%M";
      };
    };
  };
}
