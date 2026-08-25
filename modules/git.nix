# git configuration. Identity comes from lazyshell.git.* so the work machine
# can use a different email without touching this file.
#
# `programs.git.settings` maps 1:1 onto ~/.config/git/config sections.
{ config, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = config.lazyshell.git.userName;
        email = config.lazyshell.git.userEmail;
      };

      alias = {
        st = "status --short --branch";
        co = "checkout";
        br = "branch";
        ci = "commit";
        amend = "commit --amend --no-edit";
        lg = "log --graph --pretty=format:'%C(yellow)%h%Creset %C(blue)%an%Creset %C(green)%ar%Creset %s%C(auto)%d%Creset'";
        last = "log -1 --stat";
        unstage = "reset HEAD --";
        wip = "commit --no-verify -m WIP";
      };

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      rebase.autosquash = true;
      diff.colorMoved = "default";
      merge.conflictstyle = "zdiff3";
      rerere.enabled = true;
      column.ui = "auto";
      branch.sort = "-committerdate";
    };

    ignores = [
      "result"
      "result-*"
      ".direnv/"
      ".DS_Store"
      "*.swp"
    ];
  };

  # delta gives word-level diffs with syntax highlighting, wired into git.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
    };
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };
}
