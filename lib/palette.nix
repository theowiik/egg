# Shared tangerine, pastel peach, mint, and butter yellow colors for the shell UI.
{ lib }:
let
  rgb = {
    frame = "68;52;46";
    brand = "255;145;77";
    clock = "255;122;38";
    dir = "255;193;157";
    git = "177;226;197";
    dirty = "255;185;110";
    path = "255;193;157";
    nix = "199;208;245";
    slow = "249;222;151";
    err = "255;141;122";
    muted = "160;146;135";
    text = "255;243;233";
    surface = "35;30;27";
    overlay = "64;53;47";
    subtle = "211;188;167";
  };
  hexByte = n: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString n));
in
{
  hex = lib.mapAttrs (
    _: value:
    "#${lib.concatMapStrings (part: hexByte (builtins.fromJSON part)) (lib.splitString ";" value)}"
  ) rgb;
  ansi = lib.mapAttrs (_: value: "38;2;${value}") rgb;
}
