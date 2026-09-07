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
    INTERACTIVE_TESTS = ./interactive.py;
    PROFILE = "${home.config.home.path}";
  }
  ''
    python ${./smoke.py}
    touch "$out"
  ''
