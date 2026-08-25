# Small option namespace so host files stay declarative one-liners
# instead of copy-pasted blocks of program config.
{ lib, ... }:
{
  options.lazyshell = {
    profile = lib.mkOption {
      type = lib.types.enum [
        "personal"
        "work"
      ];
      default = "personal";
      description = "Which flavour of machine this is. Modules can branch on it.";
    };

    git = {
      userName = lib.mkOption {
        type = lib.types.str;
        default = "Theo Wiik";
        description = "git user.name for this machine.";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        default = "you@example.com";
        description = "git user.email for this machine (work machines override this).";
      };
    };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.awscli2 pkgs.kubectl ]";
      description = "Machine-specific packages, on top of the shared toolbox.";
    };
  };
}
