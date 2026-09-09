# helix — modal editor with LSP support built in, no plugin manager.
{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = true; # sets $EDITOR; don't also set it in home.nix

    # Language servers helix will pick up automatically.
    extraPackages = with pkgs; [
      nil # nix
      nixfmt
      marksman # markdown
      taplo # toml
      bash-language-server
      yaml-language-server
    ];

    settings = {
      theme = "tokyonight_storm";

      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true; # mode colours the statusline
        bufferline = "multiple";
        true-color = true;
        completion-trigger-len = 1;
        idle-timeout = 50;
        rulers = [ 100 ];
        scrolloff = 6;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides = {
          render = true;
          character = "┊";
        };

        file-picker.hidden = false; # show dotfiles in the picker
        soft-wrap.enable = true;

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
      };

      keys.normal = {
        # Space is the leader key in helix; these are the two you reach for.
        space.w = ":write";
        space.q = ":quit";
        # Esc also clears the selection, which is the usual surprise for vim users.
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
      };
    };

    languages = {
      language-server.nil.command = "nil";

      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "nixfmt";
          language-servers = [ "nil" ];
        }
      ];
    };
  };
}
