{
  pkgs,
  home,
  preview,
  install,
  previewRoot,
}:
pkgs.runCommand "lazyshell-smoke"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    PREVIEW = "${preview}/bin/lazyshell-try";
    INSTALL = "${install}/bin/lazyshell-install";
    PREVIEW_ROOT = previewRoot;
    PROFILE = "${home.config.home.path}";
  }
  ''
    python ${./smoke.py}
    touch "$out"
  ''
