# Small option namespace so host files stay declarative one-liners
# instead of copy-pasted blocks of program config.
{ config, lib, ... }:
{
  options.egg = {
    directory = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/git/lazyshell";
      description = "Repository path used by rebuild, news and edit commands; EGG_DIR overrides it.";
    };
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

    toolbox = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            category = lib.mkOption {
              type = lib.types.str;
              description = "Heading this tool is listed under by `egg help`.";
            };
            cmd = lib.mkOption {
              type = lib.types.str;
              description = "The command you actually type.";
            };
            package = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = null;
              description = "Package to install, or null when a programs.* module already installs it.";
            };
            desc = lib.mkOption {
              type = lib.types.str;
              description = "One line explaining what it is for.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        The toolbox. Single source of truth: `modules/packages.nix` installs
        every entry with a package, and `egg help` lists all of them.
        Order is preserved, so entries render in the order written.
      '';
    };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.awscli2 pkgs.kubectl ]";
      description = "Machine-specific packages, on top of the shared toolbox.";
    };
  };
}
