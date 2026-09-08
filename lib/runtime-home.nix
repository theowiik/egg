# Local settings are read from the live filesystem, outside the Git flake source.
{
  mkHome,
  system,
  username,
  homeDirectory,
  directory,
  localFile,
}:
mkHome {
  inherit system username homeDirectory;
  host = "personal";
  extraModules = [
    ({ lib, ... }: {
      egg.directory = lib.mkDefault directory;
      egg.localConfigFile = lib.mkDefault localFile;
    })
  ]
  ++ (if builtins.pathExists localFile then [ (builtins.toPath localFile) ] else [ ]);
}
