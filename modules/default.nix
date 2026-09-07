# Aggregator: adding a module means dropping a file here and listing it.
{ ... }:
{
  imports = [
    ./options.nix
    ./packages.nix
    ./nix.nix
    ./zsh.nix
    ./completions.nix
    ./aliases.nix
    ./eza.nix
    ./editor.nix
    ./help.nix
    ./git.nix
    ./prompt.nix
    ./welcome.nix
    ./navigation.nix
  ];
}
