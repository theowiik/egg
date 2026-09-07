# Aliases. There are deliberately few: egg's own maintenance commands, and
# `ls` over in modules/eza.nix. Nothing else shadows a standard command, so
# `cat`, `du`, `ps` and `grep` still run the real thing.
{ ... }:
{
  home.shellAliases = {
    hms = "egg switch";
    hmn = "egg news";
  };
}
