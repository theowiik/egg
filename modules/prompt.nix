# Prompt. Two lines, framed, with a lazyshell badge so it is always obvious
# which environment you are standing in.
#
# Deliberately built from plain Unicode (box drawing, ⚡, ❯) rather than
# Nerd Font glyphs: those live in the private use area and render as tofu
# unless the terminal is set to a patched font — which on WSL means
# installing it on the Windows side, not here.
{ lib, ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;
      command_timeout = 1000;
      palette = "lazyshell";

      palettes.lazyshell = {
        frame = "#585b70";
        brand = "#cba6f7";
        dir = "#89b4fa";
        git = "#a6e3a1";
        dirty = "#f9e2af";
        nix = "#74c7ec";
        slow = "#fab387";
        err = "#f38ba8";
        muted = "#6c7086";
      };

      format = lib.concatStrings [
        "[╭─](frame)"
        "[ ⚡ lazyshell ](bold brand)"
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
        "[╰─](frame)"
        "$character"
      ];

      right_format = "$time";

      username = {
        format = "[$user]($style)";
        style_user = "bold dir";
        style_root = "bold err";
        show_always = false;
      };
      hostname = {
        ssh_only = true;
        format = "[@$hostname ](bold dir)";
      };
      jobs = {
        format = "[│](frame)[ $number jobs ](bold nix)";
        number_threshold = 1;
        symbol_threshold = 1;
      };
      status = {
        disabled = false;
        format = "[│](frame)[ exit $status ](bold err)";
      };

      directory = {
        format = "[│](frame)[ $path ]($style)[$read_only]($read_only_style)";
        style = "bold dir";
        truncation_length = 4;
        truncate_to_repo = false;
        read_only = " ro ";
        read_only_style = "bold err";
      };

      git_branch = {
        format = "[│](frame)[ $branch ]($style)";
        style = "bold git";
      };

      git_status = {
        format = "([$all_status$ahead_behind ]($style))";
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

      git_state.format = "[│](frame)[ $state $progress_current/$progress_total ](bold err)";

      # ❄ marks a `nix develop` / `nix shell` subshell.
      nix_shell = {
        format = "[│](frame)[ ❄ $state ]($style)";
        style = "bold nix";
        impure_msg = "impure";
        pure_msg = "pure";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[│](frame)[ took $duration ]($style)";
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
