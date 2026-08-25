# zsh itself: history, options, keybindings, plugins.
# Completions live in modules/completions.nix, aliases in modules/aliases.nix.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;

    # Keep $HOME tidy: the real zshrc lives at ~/.config/zsh/.zshrc and
    # home-manager writes a tiny ~/.zshenv that points ZDOTDIR at it.
    dotDir = "${config.xdg.configHome}/zsh";

    # Both are home-manager-managed zsh plugins, no plugin manager needed.
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Completion machinery is switched on here; tuned in completions.nix.
    enableCompletion = true;

    history = {
      size = 100000;
      save = 100000;
      path = "${config.xdg.dataHome}/zsh/history";
      extended = true; # record timestamps
      ignoreDups = true;
      ignoreSpace = true; # leading space keeps a command out of history
      expireDuplicatesFirst = true;
      share = true; # history is live across open terminals
    };

    # `initContent` replaces the old `initExtra`. mkOrder 550 runs *before*
    # compinit, mkOrder 1000 runs at the end of .zshrc.
    initContent = lib.mkMerge [
      (lib.mkOrder 1000 ''
        # --- shell options -------------------------------------------------
        setopt AUTO_CD              # `foo/` instead of `cd foo/`
        setopt AUTO_PUSHD           # keep a directory stack
        setopt PUSHD_IGNORE_DUPS
        setopt EXTENDED_GLOB
        setopt GLOB_DOTS            # globs match dotfiles
        setopt INTERACTIVE_COMMENTS # allow `# comments` when typing
        setopt NO_BEEP
        setopt CORRECT              # offer to fix typo'd command names

        # --- keybindings ---------------------------------------------------
        bindkey -e                  # emacs bindings; swap for `bindkey -v`

        # Up/Down search history using what is already typed.
        autoload -U up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey '^[[A' up-line-or-beginning-search
        bindkey '^[[B' down-line-or-beginning-search
        bindkey '^[[1;5C' forward-word   # ctrl-right
        bindkey '^[[1;5D' backward-word  # ctrl-left

        # Accept the autosuggestion with ctrl-space.
        bindkey '^ ' autosuggest-accept

        # --- machine-local escape hatch ------------------------------------
        # Anything secret or one-off (work proxies, tokens) goes here and is
        # never committed. Create it by hand on the machine that needs it.
        [[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
      '')
    ];
  };
}
