{
  pkgs,
  runtimeHome,
  system,
}:
let
  args = {
    inherit system;
    username = "new-user";
    homeDirectory = "/tmp/egg user/home";
    directory = "/tmp/egg checkout";
  };
  missing = runtimeHome (args // { localFile = "${./.}/does-not-exist.nix"; });
  present = runtimeHome (args // { localFile = toString ./local.nix; });
in
assert missing.config.egg.git.userName == "";
assert missing.config.egg.git.userEmail == "";
assert missing.config.egg.profile == "personal";
assert missing.config.egg.extraPackages == [ ];
assert present.config.egg.git.userName == "Egg Test";
assert present.config.programs.git.settings.user.email == "egg@test.invalid";
assert present.config.egg.profile == "work";
assert builtins.length present.config.egg.extraPackages == 2;
assert present.config.home.username == args.username;
assert present.config.home.homeDirectory == args.homeDirectory;
assert present.config.egg.directory == args.directory;
assert present.config.egg.localConfigFile == toString ./local.nix;
pkgs.writeText "egg-runtime-checked" "Runtime configuration assertions passed"
