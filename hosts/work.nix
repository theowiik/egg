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
    ];
  };

}
