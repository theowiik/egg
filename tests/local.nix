{ pkgs, ... }:
{
  egg.git.userName = "Egg Test";
  egg.git.userEmail = "egg@test.invalid";
  egg.extraPackages = with pkgs; [
    kubectl
    awscli2
  ];
}
