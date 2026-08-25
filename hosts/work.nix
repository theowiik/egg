# Work machine. Different identity, different extra tooling.
{ pkgs, ... }:
{
  lazyshell = {
    profile = "work";
    git.userEmail = "theo.wiik@example-corp.com"; # <- set your work address

    extraPackages = with pkgs; [
      # Typical work-only tooling; trim to taste.
      kubectl
      awscli2
      jq
    ];
  };

  # Work often wants a different identity only under a specific directory;
  # this is the declarative version of a gitconfig `includeIf`.
  programs.git.includes = [
    {
      condition = "gitdir:~/work/";
      contents.user.email = "theo.wiik@example-corp.com";
    }
  ];
}
