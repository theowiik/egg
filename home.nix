# Shared base configuration — everything every machine gets.
# Shared profiles live in hosts/*.nix; user settings live in configs/*.nix.
{
  inputs,
  ...
}:
{
  imports = [ ./modules ];

  # Let home-manager manage itself, so `home-manager` is always on PATH
  # at the version this flake pins.
  programs.home-manager.enable = true;

  home = {
    # Bump only after reading the release notes; it is not "the current version".
    stateVersion = "24.11";

    sessionVariables = {
      # EDITOR is set by programs.helix.defaultEditor in modules/editor.nix.
      VISUAL = "hx";
      PAGER = "less -FRX";
      # Colourful man pages via bat, which is installed in modules/packages.nix.
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };
  };

  # XDG dirs keep $HOME tidy and give the modules a predictable place to write.
  xdg.enable = true;

  # Nice-to-have on non-NixOS machines: the flake registry points `nixpkgs`
  # at the exact revision this config was built with.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
}
