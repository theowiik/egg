# Personal machine.
{ ... }:
{
  lazyshell = {
    profile = "personal";
    git.userEmail = "you@example.com";
  };

  # Packages only this machine needs.
  # lazyshell.extraPackages = with pkgs; [ ffmpeg yt-dlp ];
}
