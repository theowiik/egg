# Full-screen terminal apps.
{ lib, ... }:
let
  colors = (import ../lib/palette.nix { inherit lib; }).hex;
in
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
            "${colors.brand}"
            "bold"
          ];
          inactiveBorderColor = [ "${colors.frame}" ];
          optionsTextColor = [ "${colors.dir}" ];
          selectedLineBgColor = [ "${colors.surface}" ];
          cherryPickedCommitBgColor = [ "${colors.overlay}" ];
          cherryPickedCommitFgColor = [ "${colors.brand}" ];
          unstagedChangesColor = [ "${colors.err}" ];
          defaultFgColor = [ "${colors.text}" ];
          searchingActiveBorderColor = [
            "${colors.dirty}"
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
      theme = "tokyo-night-storm";
      pane_frames = true;
      ui.pane_frames.rounded_corners = false;
      copy_on_select = true;
      default_layout = "compact";
    };
  };
}
