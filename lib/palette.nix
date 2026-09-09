# Shared yolk yellow, eggshell cream, and warm charcoal colors for the shell UI.
{ lib }:
let
  rgb = {
    frame = "49;45;38";
    brand = "255;200;61";
    dir = "255;200;61";
    git = "239;230;211";
    dirty = "242;163;40";
    path = "35;33;29";
    nix = "213;195;159";
    slow = "242;163;40";
    err = "242;100;65";
    muted = "137;130;116";
    text = "250;246;235";
    surface = "18;17;14";
    overlay = "45;42;35";
    subtle = "191;182;162";
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
