# Jumping around: fzf, zoxide, direnv. All wired into zsh by home-manager.
{ lib, ... }:
let
  colors = (import ../lib/palette.nix { inherit lib; }).hex;
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Respect .gitignore and include dotfiles, but never walk into .git.
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height=70%"
      "--layout=reverse"
      "--border=double"
      "--padding=1,2"
      "--border-label=' SCAN // egg '"
      "--prompt='SCAN ❯ '"
      "--pointer='▶'"
      "--marker='◆'"
      "--color=bg:${colors.surface},bg+:${colors.overlay},fg:${colors.text},fg+:${colors.text},hl:${colors.dir},hl+:${colors.cyan}"
      "--color=border:${colors.dir},header:${colors.brand},info:${colors.subtle},prompt:${colors.brand},pointer:${colors.brand},marker:${colors.git},spinner:${colors.brand}"
      "--info=inline"
    ];
    # ctrl-t — insert a file path, with a preview.
    fileWidget = {
      command = "fd --type f --hidden --exclude .git";
      options = [
        "--prompt='FILE ❯ '"
        "--header='Enter: insert path · Tab: select more · Esc: cancel'"
        "--preview 'bat --style=numbers --color=always --line-range=:200 -- {}'"
      ];
    };

    # alt-c — cd into a directory, previewed as a tree.
    changeDirWidget = {
      command = "fd --type d --hidden --exclude .git";
      options = [
        "--prompt='JUMP ❯ '"
        "--header='Enter: open directory · Esc: cancel'"
        "--preview 'eza --tree --level=2 --color=always -- {}'"
      ];
    };
  };

  # `z foo` jumps to the most-used directory matching foo.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Per-project environments via .envrc; nix-direnv caches the dev shell.
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
