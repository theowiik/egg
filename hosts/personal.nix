# Personal machine.
{ ... }:
{
  egg = {
    profile = "personal";
    git.userEmail = "you@example.com";
  };

  # Packages only this machine needs.
  # egg.extraPackages = with pkgs; [ ffmpeg yt-dlp ];
}
