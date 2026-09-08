# Copy this file to personal.nix, work.nix, or another name in configs/.
# Select it with: nix run .#install -- --config <name>
{ ... }:
{
  egg.git.userName = "Your Name";
  egg.git.userEmail = "you@your-domain.org";
  # egg.profile = "work"; # default: personal; adds kubectl and awscli2
  # egg.extraPackages = [ ];
}
