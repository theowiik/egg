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
      self,
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
        "x86_64-darwin"
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

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
