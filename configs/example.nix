# Copy this file to personal.nix, work.nix, or another name in configs/.
# Select it with: nix run .#install -- --config <name>
{ pkgs, ... }:
{
  egg.git.userName = "Your Name";
  egg.git.userEmail = "you@your-domain.org";
  # egg.extraPackages = with pkgs; [ kubectl awscli2 ];
}
