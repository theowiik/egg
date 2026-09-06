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

      # -------------------------------------------------------------------
      # `nix run .#try` — the whole environment in a throwaway $HOME, so you
      # can look at it before letting it near your real dotfiles.
      #
      # The sandbox path is fixed rather than an mktemp: home-manager bakes
      # absolute paths into the generated files at *build* time, so the
      # directory has to be known before the config is built.
      # -------------------------------------------------------------------
      tryDir = "/tmp/lazyshell-try";

      mkTry =
        system:
        let
          pkgs = pkgsFor system;
          hm = mkHome {
            inherit system;
            username = "lazyshell";
            host = "personal";
            homeDirectory = tryDir;
          };
          profile = hm.config.home.path;
        in
        pkgs.writeShellApplication {
          name = "lazyshell-try";
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            try="${tryDir}"

            # Refuse to clobber a directory belonging to someone else.
            if [ -e "$try" ] && [ ! -O "$try" ]; then
              echo "lazyshell: $try exists but is not yours — remove it first" >&2
              exit 1
            fi

            # Lay the generated dotfiles out as activation would, minus the
            # part that touches your real home.
            rm -rf "$try"
            mkdir -p "$try"
            cp -rL --no-preserve=mode "${hm.activationPackage}/home-files/." "$try/"
            chmod -R u+w "$try"
            ln -sfn "${profile}" "$try/.nix-profile"

            echo "lazyshell: sandbox shell — HOME is $try, nothing outside it is touched."
            echo "           exit (ctrl-d) to drop back to your normal shell."
            echo

            export HOME="$try"
            export NIX_PROFILES="${profile}"
            export PATH="${profile}/bin:$PATH"
            exec "${hm.config.programs.zsh.package}/bin/zsh" -l
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

      # `nix run .#try` — see "Try it without activating" in the README.
      apps = forAllSystems (system: {
        try = {
          type = "app";
          program = "${mkTry system}/bin/lazyshell-try";
          meta.description = "Preview lazyshell in a temporary home directory";
        };
      });

      packages = forAllSystems (system: {
        try = mkTry system;
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

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
