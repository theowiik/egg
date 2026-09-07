{
  pkgs,
  home,
  previewRoot,
}:
pkgs.writeShellApplication {
  name = "egg-try";
  runtimeInputs = [ pkgs.coreutils ];
  text =
    pkgs.lib.replaceStrings
      [ "@previewRoot@" "@homeFiles@" "@profile@" "@zsh@" ]
      [
        previewRoot
        "${home.activationPackage}/home-files"
        "${home.config.home.path}"
        "${home.config.programs.zsh.package}/bin/zsh"
      ]
      (builtins.readFile ./preview.sh);
}
