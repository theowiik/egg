# A local-only dashboard: no network requests or expensive package scans.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.lazyshell.welcome.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Show the system dashboard in interactive login shells.";
  };

  config = {
    xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
      logo = {
        type = "data";
        source = ''
          $1    ╭──────────────╮
          $1    │              │
          $2    │   ╲          │
          $2    │    ❯  $3━━━━   $2│
          $1    │   ╱          │
          $1    │              │
          $1    ╰──────────────╯
          $3       lazyshell
        '';
        color = {
          "1" = "38;2;203;166;247";
          "2" = "38;2;137;180;250";
          "3" = "38;2;166;227;161";
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
          keys = "38;2;137;180;250";
          title = "38;2;203;166;247";
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
          format = "${config.lazyshell.profile} · ${toString (builtins.length config.lazyshell.toolbox)} tools · nix managed";
        }
        "break"
      ];
    };

    programs.zsh.initContent = lib.mkIf config.lazyshell.welcome.enable (
      lib.mkOrder 1500 ''
        # Login shells only; avoid noise in scripts, nested shells and dumb terminals.
        # Set LAZYSHELL_NO_WELCOME=1 in ~/.zshrc.local to opt out immediately.
        if [[ -o interactive && -o login && -t 1 && "''${TERM:-dumb}" != dumb && -z "''${LAZYSHELL_NO_WELCOME:-}" ]]; then
          if (( COLUMNS >= 80 )); then
            ${pkgs.fastfetch}/bin/fastfetch
          else
            ${pkgs.fastfetch}/bin/fastfetch --logo none
          fi
          print -P '%F{183}  ready when you are.%f  %F{110}lazyshell help%f · %F{110}ctrl-r%f history · %F{110}yy%f files'
          print
        fi
      ''
    );
  };
}
