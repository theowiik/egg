# Aggregator: adding a module means dropping a file here and listing it.
{ ... }:
{
  imports = [
    ./options.nix
    ./packages.nix
    ./zsh.nix
    ./completions.nix
    ./aliases.nix
    ./eza.nix
    ./editor.nix
    ./tui.nix
    ./help.nix
    ./git.nix
    ./prompt.nix
    ./navigation.nix
  ];
}
