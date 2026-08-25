# The shared CLI toolbox. Add a package here and it lands on every machine.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # --- core file/text tooling ---
      bat # cat with syntax highlighting
      fd # friendlier find
      ripgrep # fast grep
      jq # JSON
      yq-go # YAML/XML/TOML
      tree
      unzip

      # --- navigation / fuzzy finding (configured in modules/navigation.nix) ---
      fzf
      zoxide

      # --- system inspection ---
      btop
      dust # disk usage
      procs # ps replacement

      # --- git & friends (configured in modules/git.nix) ---
      git
      delta
      gh

      # --- misc quality of life ---
      curl
      wget
      tealdeer # `tldr`, short command examples
      zsh-completions # extra completion definitions, see modules/completions.nix
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      # Linux-only: macOS has pbcopy/pbpaste and its own trash handling.
      xclip
      trash-cli
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      # macOS ships an ancient coreutils; get the GNU ones under g-prefixes.
      coreutils
    ]
    ++ config.lazyshell.extraPackages;

  # tealdeer needs a cache before `tldr` works offline; harmless if it exists.
  programs.bat = {
    enable = true;
    config.theme = "ansi";
  };
}
