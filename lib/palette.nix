# Shared near-black, electric orange, and white colors for the shell UI.
{ lib }:
let
  rgb = {
    frame = "48;48;48";
    brand = "255;92;0";
    dir = "255;122;38";
    git = "255;92;0";
    dirty = "255;176;0";
    path = "36;36;36";
    nix = "190;194;200";
    slow = "255;176;0";
    err = "255;59;48";
    muted = "128;128;128";
    text = "245;245;245";
    surface = "12;12;12";
    overlay = "42;42;42";
    subtle = "180;180;180";
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
