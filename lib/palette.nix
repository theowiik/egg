# Shared charcoal, steel blue, and amber colors for the shell UI.
{ lib }:
let
  rgb = {
    frame = "55;65;75";
    brand = "218;155;55";
    dir = "115;155;185";
    git = "139;164;105";
    dirty = "205;137;61";
    path = "49;77;99";
    nix = "115;155;185";
    slow = "201;150;66";
    err = "181;62;49";
    muted = "126;135;143";
    text = "235;237;239";
    surface = "20;24;28";
    overlay = "38;45;52";
    subtle = "164;174;183";
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
