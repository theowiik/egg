# The toolbox: what gets installed, and what `egg help` lists.
#
# One list, two consumers — add an entry here and it is both installed and
# documented. `package = null` means a programs.* module already installs it;
# the entry still shows up in the help so the tool is discoverable.
#
# Deliberately small. Nothing here shadows a standard command, so `ls`, `cat`
# and `ps` still run the real thing. Grow the list when a tool earns its place.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  egg.toolbox = [
    # --- shell ---------------------------------------------------------
    {
      category = "Shell";
      cmd = "eza";
      desc = "ls with git status and a tree view; `eza --tree`";
    }
    {
      category = "Shell";
      cmd = "bat";
      desc = "cat with syntax highlighting; also colourises man pages";
    }
    {
      category = "Shell";
      cmd = "fzf";
      desc = "fuzzy finder; ctrl-r history, ctrl-t files, alt-c dirs";
    }
    {
      category = "Shell";
      cmd = "starship";
      desc = "the prompt";
    }

    # --- files & search ------------------------------------------------
    {
      category = "Files & search";
      cmd = "fd";
      package = pkgs.fd;
      desc = "find, but fast and .gitignore-aware; backs the fzf widgets";
    }
    {
      category = "Files & search";
      cmd = "rg";
      package = pkgs.ripgrep;
      desc = "recursive grep, fast";
    }

    # --- git -----------------------------------------------------------
    {
      category = "Git";
      cmd = "git";
      desc = "configured with delta diffs and a few log aliases (`git lg`)";
    }

    # --- editor --------------------------------------------------------
    {
      category = "Editor";
      cmd = "hx";
      desc = "helix: modal editor, LSP built in, no config needed";
    }

    # --- network -------------------------------------------------------
    {
      category = "Network";
      cmd = "curl";
      package = pkgs.curl;
      desc = "still the one for scripts";
    }
    {
      category = "Network";
      cmd = "wget";
      package = pkgs.wget;
      desc = "download a file";
    }
  ];

  # Install everything in the toolbox that isn't already installed by a
  # programs.* module, plus whatever this machine asked for on top.
  home.packages =
    (lib.remove null (map (t: t.package) config.egg.toolbox)) ++ config.egg.extraPackages;

  programs.bat = {
    enable = true;
    config.theme = "ansi";
  };
}
