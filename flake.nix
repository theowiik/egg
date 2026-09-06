{
  description = "lazyshell — a portable, Nix-managed shell environment (zsh + eza + friends)";

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

      # One helper so adding a machine is a three-line entry below.
      mkHome =
        {
          system,
          username,
          host,
          homeDirectory ? defaultHome system username,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = { inherit inputs system; };
          modules = [
            ./home.nix
            ./hosts/${host}.nix
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ];
        };

      # Home Manager embeds HOME in generated files, so the preview path is
      # fixed. Its parent is an atomic lock, owned and removed by the launcher.
      previewRoot = "/tmp/lazyshell-preview";
      previewHome =
        system:
        mkHome {
          inherit system;
          username = "lazyshell";
          host = "personal";
          homeDirectory = "${previewRoot}/home";
        };

      mkTry =
        system:
        import ./lib/preview.nix {
          pkgs = pkgsFor system;
          home = previewHome system;
          inherit previewRoot;
        };

      mkInstall =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.writeShellApplication {
          name = "lazyshell-install";
          runtimeInputs = [ home-manager.packages.${system}.home-manager ];
          text = ''
            if [[ "''${1:-}" = --help || "''${1:-}" = -h ]]; then
              echo 'Usage: nix run .#install -- [Home Manager switch options]'
              echo 'Uses the current directory, or LAZYSHELL_DIR, as the configuration.'
              exit 0
            fi
            dir="''${LAZYSHELL_DIR:-$PWD}"
            if [ ! -f "$dir/flake.nix" ]; then
              echo "lazyshell: no flake.nix in $dir; run from the repository or set LAZYSHELL_DIR" >&2
              exit 1
            fi
            exec home-manager switch -b backup --flake "$dir" "$@"
          '';
        };

    in
    {
      # ---------------------------------------------------------------------
      # Machines. Key format is "user@host" — that is what you pass to
      # `home-manager switch --flake .#user@host`.
      # ---------------------------------------------------------------------
      homeConfigurations = {
        "oet@puter" = mkHome {
          system = "x86_64-linux";
          username = "oet";
          host = "personal";
        };

        # Template for the work machine — edit username/system, then switch.
        "theo@work" = mkHome {
          system = "aarch64-darwin";
          username = "theo";
          host = "work";
        };
      };

      # Preview and install both use the versions pinned by this flake.
      apps = forAllSystems (system: {
        install = {
          type = "app";
          program = "${mkInstall system}/bin/lazyshell-install";
          meta.description = "Install lazyshell with the pinned Home Manager";
        };
        try = {
          type = "app";
          program = "${mkTry system}/bin/lazyshell-try";
          meta.description = "Preview lazyshell in a temporary home directory";
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

      checks = forAllSystems (system: {
        smoke = import ./tests/smoke.nix {
          pkgs = pkgsFor system;
          home = previewHome system;
          preview = mkTry system;
          install = mkInstall system;
          inherit previewRoot;
        };
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
