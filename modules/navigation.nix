# Jumping around: fzf, zoxide, direnv. All wired into zsh by home-manager.
{ ... }:
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
      "--color=bg+:#313244,fg:#cdd6f4,fg+:#cdd6f4,hl:#89b4fa,hl+:#89dceb"
      "--color=border:#585b70,header:#cba6f7,info:#a6adc8,prompt:#cba6f7,pointer:#f5c2e7,marker:#a6e3a1,spinner:#f5c2e7"
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
