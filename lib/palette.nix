# Shared Catppuccin Mocha colors for the shell and terminal applications.
{ lib }:
let
  rgb = {
    frame = "88;91;112";
    brand = "203;166;247";
    dir = "137;180;250";
    git = "166;227;161";
    dirty = "249;226;175";
    nix = "116;199;236";
    slow = "250;179;135";
    err = "243;139;168";
    muted = "108;112;134";
    text = "205;214;244";
    surface = "49;50;68";
    overlay = "69;71;90";
    subtle = "166;173;200";
    pink = "245;194;231";
    cyan = "137;220;235";
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
