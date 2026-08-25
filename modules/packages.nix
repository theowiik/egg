# The toolbox: what gets installed, and what `lazyshell help` lists.
#
# One list, two consumers — add an entry here and it is both installed and
# documented. `package = null` means a programs.* module already installs it;
# the entry still shows up in the help so the tool is discoverable.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  lazyshell.toolbox = [
    # --- shell ---------------------------------------------------------
    {
      category = "Shell";
      cmd = "eza";
      desc = "ls replacement: git status, tree view (see `lazyshell aliases`)";
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
      cmd = "zoxide";
      desc = "`z foo` jumps to the directory you use most matching foo";
    }
    {
      category = "Shell";
      cmd = "starship";
      desc = "the prompt";
    }
    {
      category = "Shell";
      cmd = "direnv";
      desc = "per-project env from .envrc, on cd";
    }
    {
      category = "Shell";
      cmd = "carapace";
      desc = "completions for hundreds of CLIs that ship none";
    }
    {
      category = "Shell";
      cmd = "zellij";
      desc = "terminal multiplexer (panes, tabs, sessions)";
    }

    # --- files & search ------------------------------------------------
    {
      category = "Files & search";
      cmd = "fd";
      package = pkgs.fd;
      desc = "find, but fast and .gitignore-aware";
    }
    {
      category = "Files & search";
      cmd = "rg";
      package = pkgs.ripgrep;
      desc = "recursive grep, fast";
    }
    {
      category = "Files & search";
      cmd = "sd";
      package = pkgs.sd;
      desc = "sed for humans: `sd before after file`";
    }
    {
      category = "Files & search";
      cmd = "yy";
      desc = "yazi file manager; exits into the directory you left off in";
    }
    {
      category = "Files & search";
      cmd = "ouch";
      package = pkgs.ouch;
      desc = "compress/extract anything without remembering tar flags";
    }
    {
      category = "Files & search";
      cmd = "tree";
      package = pkgs.tree;
      desc = "directory tree";
    }
    {
      category = "Files & search";
      cmd = "dust";
      package = pkgs.dust;
      desc = "what is eating the disk";
    }
    {
      category = "Files & search";
      cmd = "duf";
      package = pkgs.duf;
      desc = "df with readable output";
    }

    # --- git -----------------------------------------------------------
    {
      category = "Git";
      cmd = "git";
      desc = "configured with delta diffs and aliases (`git lg`, `git st`)";
    }
    {
      category = "Git";
      cmd = "lazygit";
      desc = "full-screen git UI: stage hunks, rebase, cherry-pick";
    }
    {
      category = "Git";
      cmd = "gh";
      desc = "GitHub CLI: PRs, issues, releases";
    }
    {
      category = "Git";
      cmd = "difft";
      package = pkgs.difftastic;
      desc = "structural diff that understands syntax";
    }

    # --- editor --------------------------------------------------------
    {
      category = "Editor";
      cmd = "hx";
      desc = "helix: modal editor, LSP built in, no config needed";
    }

    # --- data ----------------------------------------------------------
    {
      category = "Data";
      cmd = "jq";
      package = pkgs.jq;
      desc = "JSON processor";
    }
    {
      category = "Data";
      cmd = "yq";
      package = pkgs.yq-go;
      desc = "same for YAML, XML and TOML";
    }
    {
      category = "Data";
      cmd = "jless";
      package = pkgs.jless;
      desc = "browse a big JSON file interactively";
    }
    {
      category = "Data";
      cmd = "glow";
      package = pkgs.glow;
      desc = "render markdown in the terminal";
    }

    # --- system --------------------------------------------------------
    {
      category = "System";
      cmd = "btop";
      package = pkgs.btop;
      desc = "process and resource monitor";
    }
    {
      category = "System";
      cmd = "procs";
      package = pkgs.procs;
      desc = "ps with colour and search";
    }
    {
      category = "System";
      cmd = "fastfetch";
      package = pkgs.fastfetch;
      desc = "system summary";
    }
    {
      category = "System";
      cmd = "hyperfine";
      package = pkgs.hyperfine;
      desc = "benchmark a command properly, with warmup and stats";
    }
    {
      category = "System";
      cmd = "watchexec";
      package = pkgs.watchexec;
      desc = "re-run a command when files change";
    }

    # --- network -------------------------------------------------------
    {
      category = "Network";
      cmd = "xh";
      package = pkgs.xh;
      desc = "HTTP requests without curl's flag soup";
    }
    {
      category = "Network";
      cmd = "doggo";
      package = pkgs.doggo;
      desc = "dig with readable output";
    }
    {
      category = "Network";
      cmd = "gping";
      package = pkgs.gping;
      desc = "ping, plotted over time";
    }
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

    # --- dev -----------------------------------------------------------
    {
      category = "Dev";
      cmd = "just";
      package = pkgs.just;
      desc = "project command runner; reads a justfile";
    }
    {
      category = "Dev";
      cmd = "tokei";
      package = pkgs.tokei;
      desc = "count lines of code by language";
    }
    {
      category = "Dev";
      cmd = "tldr";
      package = pkgs.tealdeer;
      desc = "practical examples instead of a man page";
    }
    {
      category = "Dev";
      cmd = "unzip";
      package = pkgs.unzip;
      desc = "because something always needs it";
    }
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    {
      category = "Platform (Linux)";
      cmd = "xclip";
      package = pkgs.xclip;
      desc = "clipboard from the terminal";
    }
    {
      category = "Platform (Linux)";
      cmd = "trash-put";
      package = pkgs.trash-cli;
      desc = "rm that you can undo";
    }
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    {
      category = "Platform (macOS)";
      cmd = "g<tool>";
      package = pkgs.coreutils;
      desc = "GNU coreutils under g-prefixes; macOS ships ancient BSD ones";
    }
  ];

  # Install everything in the toolbox that isn't already installed by a
  # programs.* module, plus whatever this machine asked for on top.
  home.packages =
    (lib.remove null (map (t: t.package) config.lazyshell.toolbox)) ++ config.lazyshell.extraPackages;

  programs.bat = {
    enable = true;
    config.theme = "ansi";
  };

  # Completions for the many tools that ship none of their own.
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };
}
