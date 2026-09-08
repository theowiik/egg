# Optional work tools, selected with egg.profile = "work" in local.nix.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.egg.profile == "work") {
    egg.extraPackages = with pkgs; [
      kubectl
      awscli2
    ];
  };
}
