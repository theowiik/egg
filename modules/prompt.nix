# Prompt. starship is cross-platform and needs no font tricks by default.
{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;
      command_timeout = 1000;

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      directory = {
        truncation_length = 4;
        truncate_to_repo = false;
        style = "bold cyan";
      };

      git_branch.style = "bold purple";
      git_status.style = "bold yellow";

      # Keep the right side quiet; show duration only for slow commands.
      cmd_duration = {
        min_time = 2000;
        format = "[$duration](bold yellow) ";
      };

      nix_shell.format = "via [$symbol$state]($style) ";
    };
  };
}
