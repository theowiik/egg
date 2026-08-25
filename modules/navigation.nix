# Jumping around: fzf, zoxide, direnv. All wired into zsh by home-manager.
{ ... }:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Respect .gitignore and include dotfiles, but never walk into .git.
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border"
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
