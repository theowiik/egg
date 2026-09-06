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
      "--height=60%"
      "--layout=reverse"
      "--border=rounded"
      "--padding=1,2"
      "--prompt='❯ '"
      "--pointer='▌'"
      "--marker='✓'"
      "--color=bg+:${colors.surface},fg:${colors.text},fg+:${colors.text},hl:${colors.dir},hl+:${colors.cyan}"
      "--color=border:${colors.frame},header:${colors.brand},info:${colors.subtle},prompt:${colors.brand},pointer:${colors.pink},marker:${colors.git},spinner:${colors.pink}"
      "--info=inline"
    ];
    # ctrl-t — insert a file path, with a preview.
    fileWidget = {
      command = "fd --type f --hidden --exclude .git";
      options = [ "--preview 'bat --style=numbers --color=always --line-range=:200 {}'" ];
    };

    # alt-c — cd into a directory, previewed as a tree.
    changeDirWidget = {
      command = "fd --type d --hidden --exclude .git";
      options = [ "--preview 'eza --tree --level=2 --color=always {}'" ];
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
