# Muted lavender, sage, and dusty blue on a cool charcoal base.
{ lib }:
let
  rgb = {
    frame = "48;52;64";
    brand = "180;173;206";
    clock = "231;174;145";
    dir = "163;187;206";
    git = "170;195;178";
    dirty = "209;192;155";
    path = "163;187;206";
    nix = "180;173;206";
    slow = "209;192;155";
    err = "214;158;169";
    muted = "133;139;157";
    text = "220;224;232";
    surface = "31;34;43";
    overlay = "48;52;64";
    subtle = "172;179;195";
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
