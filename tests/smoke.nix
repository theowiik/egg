{
  pkgs,
  home,
  preview,
  install,
  previewRoot,
}:
pkgs.runCommand "egg-smoke"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    PREVIEW = "${preview}/bin/egg-try";
    INSTALL = "${install}/bin/egg-install";
    PREVIEW_ROOT = previewRoot;
    INSTALL_SCRIPT = pkgs.writeText "egg-install-script" (
      pkgs.lib.replaceStrings [ "@system@" ] [ pkgs.stdenv.hostPlatform.system ] (
        builtins.readFile ../lib/install.sh
      )
    );
    BASH = "${pkgs.bash}/bin/bash";
    SYSTEM = pkgs.stdenv.hostPlatform.system;
    INTERACTIVE_TESTS = ./interactive.py;
    PROFILE = "${home.config.home.path}";
  }
  ''
    python ${./install.py}
    python ${./smoke.py}
    touch "$out"
  ''
