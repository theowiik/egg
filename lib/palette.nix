# Shared playful pastel colors for the shell and terminal applications.
{ lib }:
let
  rgb = {
    frame = "90;70;150";
    brand = "215;112;184";
    dir = "105;195;212";
    git = "124;211;174";
    dirty = "225;151;202";
    nix = "166;139;216";
    slow = "220;166;112";
    err = "222;112;135";
    muted = "129;139;176";
    text = "230;240;255";
    surface = "13;16;32";
    overlay = "35;30;65";
    subtle = "172;186;220";
    pink = "215;112;184";
    cyan = "108;210;182";
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
