# Aliases. There are deliberately few: nothing here shadows a standard
# command, so `ls`, `cat`, `du`, `ps` and `grep` still run the real thing.
# Only egg's own maintenance commands get a shorthand.
{ ... }:
{
  home.shellAliases = {
    hms = "egg switch";
    hmn = "egg news";
  };
}
