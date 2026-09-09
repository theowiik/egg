# fzf: fuzzy history (ctrl-r), file paths (ctrl-t) and directories (alt-c),
# plus the handful of shell functions built on it. Wired into zsh by
# home-manager; the widgets shell out to fd and eza.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = (import ../lib/palette.nix { inherit lib; }).hex;
  fzfInit = pkgs.runCommand "egg-fzf-init.zsh" { } ''
    ${lib.getExe config.programs.fzf.package} --zsh > "$out"
  '';
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;

    # Respect .gitignore and include dotfiles, but never walk into .git.
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height=70%"
      "--layout=reverse"
      "--border=rounded"
      "--padding=1,2"
      "--border-label=' egg '"
      "--prompt='search · '"
      "--pointer='•'"
      "--marker='✓'"
      "--color=bg:${colors.surface},bg+:${colors.overlay},fg:${colors.text},fg+:${colors.text},hl:${colors.dir},hl+:${colors.brand}"
      "--color=border:${colors.muted},header:${colors.brand},info:${colors.subtle},prompt:${colors.brand},pointer:${colors.brand},marker:${colors.git},spinner:${colors.brand}"
      "--info=inline"
    ];
    # ctrl-t — insert a file path, with a preview.
    fileWidget = {
      command = "fd --type f --hidden --exclude .git";
      options = [
        "--prompt='file · '"
        "--header='Enter: insert path · Tab: select more · Esc: cancel'"
        "--preview 'bat --style=numbers --color=always --line-range=:200 -- {}'"
      ];
    };

    # alt-c — cd into a directory, previewed as a tree.
    changeDirWidget = {
      command = "fd --type d --hidden --exclude .git";
      options = [
        "--prompt='directory · '"
        "--header='Enter: open directory · Esc: cancel'"
        "--preview 'eza --tree --level=2 --color=always -- {}'"
      ];
    };
  };

  # mkcd, ff and c — new commands, none of them shadowing a standard one.
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkOrder 910 ''
      if [[ $options[zle] = on ]]; then
        source ${fzfInit}
      fi
    '')
    (lib.mkOrder 1000 (builtins.readFile ./helpers.zsh))
  ];
}
