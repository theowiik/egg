# The `egg` command — what is installed, what the aliases are, what the
# keybindings do.
#
# Everything here is rendered from config at build time: the tool list comes
# from `egg.toolbox` (the same list that installs the packages) and the
# alias list from `home.shellAliases`. Neither can drift out of date.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = (import ../lib/palette.nix { inherit lib; }).ansi;
  # Nix has no \e escape, so pull an ESC character out of JSON.
  esc = builtins.fromJSON ''"\u001b"'';
  sgr = n: "${esc}[${n}m";

  reset = sgr "0";
  brand = sgr "1;${colors.brand}"; # matches the prompt accent
  head = sgr "1;${colors.dir}";
  cmd = sgr colors.git;
  grey = sgr colors.muted;

  pad =
    n: s:
    let
      len = builtins.stringLength s;
    in
    # Always leave at least one space: a name longer than the column would
    # otherwise run straight into its description.
    s + lib.concatStrings (lib.genList (_: " ") (if n > len then n - len else 1));

  rowAt =
    width: name: desc:
    "  ${cmd}${pad width name}${reset}${grey}${desc}${reset}";
  row = rowAt 14;
  # `egg <sub>` names are longer than a tool name, so Meta gets its own
  # column width rather than wrapping every other block in dead space.
  metaRow = rowAt 18;

  tools = config.egg.toolbox;
  # lib.unique keeps first-seen order, so categories render as authored.
  categories = lib.unique (map (t: t.category) tools);

  block = c: ''
    ${head}${c}${reset}
    ${lib.concatStringsSep "\n" (map (t: row t.cmd t.desc) (lib.filter (t: t.category == c) tools))}
  '';

  banner = ''
    ${brand}  🥚 egg${reset}
    ${grey}  ${toString (builtins.length tools)} tools, nix-managed. Everything below is already installed.${reset}
  '';

  helpText = ''
    ${banner}
    ${lib.concatStringsSep "\n" (map block categories)}
    ${head}Meta${reset}
    ${metaRow "egg aliases" "every shortcut, generated from the config"}
    ${metaRow "egg keys" "keybindings"}
    ${metaRow "egg doctor" "check tools, config, activation and Git identity"}
    ${metaRow "hms / hmn" "apply configuration / read Home Manager news"}
    ${metaRow "egg edit" "open the config in $EDITOR"}
  '';

  aliasesText = ''
    ${brand}  🥚 egg aliases${reset}

    ${lib.concatStringsSep "\n" (
      map (n: row n config.home.shellAliases.${n}) (lib.attrNames config.home.shellAliases)
    )}
  '';

  keysText = ''
    ${brand}  🥚 egg keybindings${reset}

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
    ${row "c [dir]" "browse directories below here or a given path"}
    ${row "cd -" "return to the previous directory"}
    ${row "mkcd <dir>" "make a directory and enter it"}
    ${row "ff [pat]" "fuzzy-find a file and open it in the editor"}
  '';

  helpFile = pkgs.writeText "egg-help" helpText;
  aliasesFile = pkgs.writeText "egg-aliases" aliasesText;
  keysFile = pkgs.writeText "egg-keys" keysText;

  egg = pkgs.writeShellApplication {
    name = "egg";
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
          # Strip colour when piped, so `egg | grep` behaves.
          sed 's/\x1b\[[0-9;]*m//g' "$1"
        fi
      }

      dir=${lib.escapeShellArg config.egg.directory}
      dir="''${EGG_DIR:-$dir}"
      local_config=${lib.escapeShellArg config.egg.localConfigFile}
      local_config="''${EGG_CONFIG:-$local_config}"

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
          ${builtins.readFile ./doctor.sh}
          ;;
        switch | news)
          action="$1"
          shift
          if [ "$action" = news ]; then
            set -- --news "$@"
          fi
          export EGG_DIR="$dir" EGG_CONFIG="$local_config"
          exec nix --extra-experimental-features 'nix-command flakes' run "$dir#install" -- "$@"
          ;;
        edit)
          cd "$dir" && exec ''${EDITOR:-hx} .
          ;;
        *)
          printf 'egg: unknown subcommand %s\n\n' "$1" >&2
          show ${helpFile}
          exit 1
          ;;
      esac
    '';
  };
in
{
  home.packages = [ egg ];
}
