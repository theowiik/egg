{
  description = "egg — a portable, Nix-managed shell environment (zsh + eza + friends)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;

      # Every platform we might ever land on: work laptop, personal box, a VM.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = f: lib.genAttrs systems (system: f system);

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      # Home directories differ between macOS and Linux; derive it unless told otherwise.
      defaultHome =
        system: username:
        if lib.hasSuffix "darwin" system then "/Users/${username}" else "/home/${username}";

      # Shared constructor for named machines, runtime installs and previews.
      mkHome =
        {
          system,
          username,
          host,
          homeDirectory ? defaultHome system username,
          extraModules ? [ ],
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = { inherit inputs system; };
          modules = [
            ./home.nix
            ./hosts/personal.nix
            ./hosts/work.nix
            {
              egg.profile = lib.mkDefault host;
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ]
          ++ extraModules;
        };

      runtimeHome = args: import ./lib/runtime-home.nix ({ inherit mkHome; } // args);

      # Home Manager embeds HOME in generated files, so the preview path is
      # fixed. Its parent is an atomic lock, owned and removed by the launcher.
      previewRoot = "/tmp/egg-preview";
      previewHome =
        system: root:
        mkHome {
          inherit system;
          username = "egg";
          host = "personal";
          homeDirectory = "${root}/home";
        };

      mkTry =
        system:
        import ./lib/preview.nix {
          pkgs = pkgsFor system;
          home = previewHome system previewRoot;
          inherit previewRoot;
        };

      mkInstall =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.writeShellApplication {
          name = "egg-install";
          runtimeInputs = [
            home-manager.packages.${system}.home-manager
            pkgs.coreutils
          ];
          text = lib.replaceStrings [ "@system@" ] [ system ] (builtins.readFile ./lib/install.sh);
        };

    in
    {
      # ---------------------------------------------------------------------
      # Machines. Key format is "user@host" — that is what you pass to
      # `home-manager switch --flake .#user@host`.
      # ---------------------------------------------------------------------
      homeConfigurations = (rec {
        "oet@puter" = mkHome {
          system = "x86_64-linux";
          username = "oet";
          host = "personal";
        };

        # Personal Mac, also selectable explicitly with --flake .#neo.
        neo = mkHome {
          system = "aarch64-darwin";
          username = "theo";
          host = "personal";
        };

        # Compatibility for existing direct Home Manager invocations.
        "theo@Theos-MacBook-Neo.local" = neo;
      })
      // lib.optionalAttrs (builtins.getEnv "EGG_SYSTEM" != "") {
        # Only exposed by the installer: pure checks/previews never read local state.
        current = runtimeHome {
          system = builtins.getEnv "EGG_SYSTEM";
          username = builtins.getEnv "EGG_USERNAME";
          homeDirectory = builtins.getEnv "EGG_HOME";
          directory = builtins.getEnv "EGG_DIR";
          localFile = builtins.getEnv "EGG_CONFIG";
        };
      };

      # Preview and install both use the versions pinned by this flake.
      apps = forAllSystems (system: {
        install = {
          type = "app";
          program = "${mkInstall system}/bin/egg-install";
          meta.description = "Install egg with the pinned Home Manager";
        };
        try = {
          type = "app";
          program = "${mkTry system}/bin/egg-try";
          meta.description = "Preview egg in a temporary home directory";
        };
      });

      packages = forAllSystems (system: {
        try = mkTry system;
        install = mkInstall system;
      });

      # `nix develop` gives you home-manager + formatter without installing them.
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              home-manager.packages.${system}.home-manager
              pkgs.nixfmt
              pkgs.git
            ];
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          testRoot = "/tmp/egg-smoke-preview";
          home = previewHome system testRoot;
        in
        {
          runtime = import ./tests/runtime.nix { inherit pkgs runtimeHome system; };
          smoke = import ./tests/smoke.nix {
            inherit pkgs home;
            preview = import ./lib/preview.nix {
              inherit pkgs home;
              previewRoot = testRoot;
            };
            install = mkInstall system;
            previewRoot = testRoot;
          };
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.writeShellApplication {
          name = "egg-fmt";
          runtimeInputs = [ pkgs.nixfmt ];
          text = ''
            exec nixfmt "$@" ./*.nix ./hosts/*.nix ./lib/*.nix ./modules/*.nix ./tests/*.nix ./configs/example.nix
          '';
        }
      );
    };
}
