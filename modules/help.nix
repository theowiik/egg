# The `lazyshell` command — what is installed, what the aliases are, what the
# keybindings do.
#
# Everything here is rendered from config at build time: the tool list comes
# from `lazyshell.toolbox` (the same list that installs the packages) and the
# alias list from `home.shellAliases`. Neither can drift out of date.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Nix has no \e escape, so pull an ESC character out of JSON.
  esc = builtins.fromJSON ''"\u001b"'';
  sgr = n: "${esc}[${n}m";

  reset = sgr "0";
  brand = sgr "1;38;2;203;166;247"; # matches the prompt badge
  head = sgr "1;38;2;137;180;250";
  cmd = sgr "38;2;166;227;161";
  grey = sgr "38;2;108;112;134";

  pad =
    n: s:
    let
      len = builtins.stringLength s;
    in
    s + lib.concatStrings (lib.genList (_: " ") (if n > len then n - len else 0));

  row = name: desc: "  ${cmd}${pad 14 name}${reset}${grey}${desc}${reset}";

  tools = config.lazyshell.toolbox;
  # lib.unique keeps first-seen order, so categories render as authored.
  categories = lib.unique (map (t: t.category) tools);

  block = c: ''
    ${head}${c}${reset}
    ${lib.concatStringsSep "\n" (map (t: row t.cmd t.desc) (lib.filter (t: t.category == c) tools))}
  '';

  banner = ''
    ${brand}  lazyshell${reset}
    ${grey}  ${toString (builtins.length tools)} tools, nix-managed. Everything below is already installed.${reset}
  '';

  helpText = ''
    ${banner}
    ${lib.concatStringsSep "\n" (map block categories)}
    ${head}Meta${reset}
    ${row "lazyshell aliases" "every shortcut, generated from the config"}
    ${row "lazyshell keys" "keybindings"}
    ${row "lazyshell doctor" "is this environment actually active?"}
    ${row "lazyshell edit" "open the config in $EDITOR"}
  '';

  aliasesText = ''
    ${brand}  lazyshell aliases${reset}

    ${lib.concatStringsSep "\n" (
      map (n: row n config.home.shellAliases.${n}) (lib.attrNames config.home.shellAliases)
    )}
  '';

  keysText = ''
    ${brand}  lazyshell keybindings${reset}

    ${head}Finding things${reset}
    ${row "ctrl-r" "fuzzy search shell history"}
    ${row "ctrl-t" "insert a file path, with preview"}
    ${row "alt-c" "cd into a directory, with tree preview"}

    ${head}Editing the line${reset}
    ${row "ctrl-space" "accept the greyed-out suggestion"}
    ${row "up / down" "history search using what you already typed"}
    ${row "ctrl-left/right" "move by word"}
    ${row "tab" "completion menu, arrows to pick"}

    ${head}Navigation${reset}
    ${row "z <part>" "jump to a frequently used directory"}
    ${row "mkcd <dir>" "make a directory and enter it"}
    ${row "up [n]" "climb n directories"}
    ${row "ff [pat]" "fuzzy-find a file and open it in the editor"}
    ${row "yy" "file manager, exits into the directory you left off in"}
  '';

  helpFile = pkgs.writeText "lazyshell-help" helpText;
  aliasesFile = pkgs.writeText "lazyshell-aliases" aliasesText;
  keysFile = pkgs.writeText "lazyshell-keys" keysText;

  lazyshell = pkgs.writeShellApplication {
    name = "lazyshell";
    runtimeInputs = [
      pkgs.less
      pkgs.gnused
      pkgs.coreutils
    ];
    text = ''
      show() {
        if [ -t 1 ]; then
          less -FRX "$1"
        else
          # Strip colour when piped, so `lazyshell | grep` behaves.
          sed 's/\x1b\[[0-9;]*m//g' "$1"
        fi
      }

      dir="''${LAZYSHELL_DIR:-$HOME/git/lazyshell}"

      case "''${1:-help}" in
        help | -h | --help)
          show ${helpFile}
          ;;
        aliases)
          show ${aliasesFile}
          ;;
        keys)
          show ${keysFile}
          ;;
        doctor)
          printf '%-12s %s\n' "config" "$dir"
          printf '%-12s %s\n' "shell" "''${SHELL:-unknown}"
          printf '%-12s %s\n' "editor" "''${EDITOR:-unset}"
          if [ -e "$HOME/.local/state/nix/profiles/home-manager" ]; then
            printf '%-12s %s\n' "generation" "$(readlink -f "$HOME/.local/state/nix/profiles/home-manager")"
          else
            printf '%-12s %s\n' "generation" "not activated - see the README"
          fi
          ;;
        edit)
          cd "$dir" && exec ''${EDITOR:-hx} .
          ;;
        *)
          printf 'lazyshell: unknown subcommand %s\n\n' "$1" >&2
          show ${helpFile}
          exit 1
          ;;
      esac
    '';
  };
in
{
  home.packages = [ lazyshell ];
}
