# Full-screen terminal apps.
{ ... }:
{
  # `lazygit` — stage hunks, rebase, cherry-pick without memorising flags.
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        showIcons = false; # icons need a Nerd Font, see modules/prompt.nix
        nerdFontsVersion = "";
        showFileTree = true;
        mouseEvents = true;
        theme = {
          activeBorderColor = [
            "#cba6f7"
            "bold"
          ];
          inactiveBorderColor = [ "#585b70" ];
          optionsTextColor = [ "#89b4fa" ];
          selectedLineBgColor = [ "#313244" ];
          cherryPickedCommitBgColor = [ "#45475a" ];
          cherryPickedCommitFgColor = [ "#cba6f7" ];
          unstagedChangesColor = [ "#f38ba8" ];
          defaultFgColor = [ "#cdd6f4" ];
          searchingActiveBorderColor = [
            "#f9e2af"
            "bold"
          ];
        };
      };
      git.paging = {
        colorArg = "always";
        pager = "delta --dark --paging=never";
      };
    };
  };

  # `yy` — file manager that cds the shell to wherever you left off.
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "yy";
  };

  # Multiplexer. Integration is deliberately OFF: home-manager's zsh
  # integration auto-starts zellij in *every* new shell, which hijacks the
  # terminal. Start it yourself with `zellij`.
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      theme = "catppuccin-mocha";
      pane_frames = true;
      ui.pane_frames.rounded_corners = true;
      copy_on_select = true;
      default_layout = "compact";
    };
  };
}
