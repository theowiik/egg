# Instant shell welcome; the full hardware dashboard is available on demand.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = (import ../lib/palette.nix { inherit lib; }).ansi;
  platform = if pkgs.stdenv.hostPlatform.isDarwin then "macOS" else "Linux";

in
{
  options.egg.welcome.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Show a neon console welcome in interactive login shells (no hardware detection).";
  };

  config = {
    xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
      logo = {
        type = "data";
        source = ''
          $1    ╭────────────╮
          $2    │   🥚 egg   │
          $1    ╰────────────╯
        '';
        color = {
          "1" = colors.brand;
          "2" = colors.dir;
          "3" = colors.git;
        };
        padding = {
          top = 1;
          right = 4;
        };
      };
      display = {
        separator = "  ";
        key.width = 12;
        color = {
          keys = colors.dir;
          title = colors.brand;
        };
        bar = {
          char.elapsed = "━";
          char.total = "─";
          width = 10;
        };
      };
      modules = [
        "break"
        "title"
        {
          type = "custom";
          format = "────────── system ──────────";
        }
        {
          type = "os";
          key = "OS";
        }
        {
          type = "host";
          key = "Machine";
        }
        {
          type = "kernel";
          key = "Kernel";
        }
        {
          type = "uptime";
          key = "Uptime";
        }
        {
          type = "cpu";
          key = "CPU";
        }
        {
          type = "memory";
          key = "Memory";
          percent.type = 3;
        }
        {
          type = "disk";
          key = "Disk";
          folders = "/";
          percent.type = 3;
        }
        {
          type = "custom";
          format = "──────── workspace ─────────";
        }
        {
          type = "shell";
          key = "Shell";
        }
        {
          type = "terminal";
          key = "Terminal";
        }
        {
          type = "custom";
          key = "Profile";
          format = "${config.egg.profile} · ${toString (builtins.length config.egg.toolbox)} tools · nix managed";
        }
        "break"
      ];
    };

    programs.zsh.initContent = lib.mkIf config.egg.welcome.enable (
      lib.mkOrder 1500 ''
        # Login shells only; avoid noise in scripts, nested shells and dumb terminals.
        # Set EGG_NO_WELCOME=1 in ~/.zshrc.local to opt out immediately.
        if [[ -o interactive && -o login && -t 1 && "''${TERM:-dumb}" != dumb && -z "''${EGG_NO_WELCOME:-}" ]]; then
          # Only shell builtins here: no fastfetch, subprocesses or hardware probes.
          print
          printf '\033[${colors.brand}m  ╭── 🥚 egg ─────────────────╮\033[0m\n'
          printf '\033[${colors.dir}m     SHELL CONSOLE  //  READY\033[0m\n'
          printf '\033[${colors.brand}m  ╰──────────────────────────╯\033[0m\n'
          printf '\033[0m\033[${colors.subtle}m  %s\033[0m\n' '${config.egg.profile} / ${platform} / ${toString (builtins.length config.egg.toolbox)} tools'
          printf '\033[${colors.dir}m  egg help  /  egg fetch\033[0m\n'
          print
        fi
      ''
    );
  };
}
