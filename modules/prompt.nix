# A compact two-line prompt: lavender identity badge, slate directory segment,
# and quiet status separators. Plain Unicode; no patched font required.
{ lib, ... }:
let
  colors = (import ../lib/palette.nix { inherit lib; }).hex;
in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;
      command_timeout = 1000;
      palette = "lazyshell";

      palettes.lazyshell = colors;

      format = lib.concatStrings [
        "[ lazyshell ](bold fg:surface bg:brand)"
        "$directory"
        "$username"
        "$hostname"
        "$git_branch"
        "$git_status"
        "$git_state"
        "$nix_shell"
        "$cmd_duration"
        "$jobs"
        "$status"
        "$line_break"
        " "
        "$character"
      ];

      right_format = "$time";

      username = {
        format = "[ · ](frame)[$user]($style)";
        style_user = "bold dir";
        style_root = "bold err";
        show_always = false;
      };
      hostname = {
        ssh_only = true;
        format = "[@$hostname](bold dir)";
      };
      jobs = {
        format = "[ · ](frame)[$number jobs](nix)";
        number_threshold = 1;
        symbol_threshold = 1;
      };
      status = {
        disabled = false;
        format = "[ · ](frame)[exit $status](bold err)";
      };

      directory = {
        format = "[ $path ]($style)[$read_only]($read_only_style)";
        style = "bold fg:dir bg:surface";
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo = false;
        read_only = " ro ";
        read_only_style = "bold fg:err bg:surface";
      };

      git_branch = {
        format = "[ · ](frame)[$branch]($style)";
        style = "bold git";
      };

      git_status = {
        format = "([ $all_status$ahead_behind]($style))";
        style = "bold dirty";
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

      git_state.format = "[ · ](frame)[$state $progress_current/$progress_total](bold err)";

      # ❄ marks a `nix develop` / `nix shell` subshell.
      nix_shell = {
        format = "[ · ](frame)[❄ $state]($style)";
        style = "bold nix";
        impure_msg = "impure";
        pure_msg = "pure";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[ · ](frame)[$duration]($style)";
        style = "bold slow";
      };

      character = {
        success_symbol = "[❯](bold brand)";
        error_symbol = "[❯](bold err)";
        vimcmd_symbol = "[❮](bold git)";
      };

      time = {
        disabled = false;
        format = "[$time ](muted)";
        time_format = "%H:%M";
      };
    };
  };
}
