# Put nix — and everything it installs — on PATH.
#
# The nix installer normally does this by appending a snippet to the user's
# hand-written ~/.zshrc. `programs.zsh.dotDir` moves the real zshrc to
# ~/.config/zsh, which orphans that ~/.zshrc: the snippet stops running, and
# with it `nix`, `home-manager` and every `egg.toolbox` tool drop off
# PATH. macOS has no /etc/zshrc nix snippet to fall back on, so the shell ends
# up with none of its own tools — `egg: command not found`.
#
# `home.sessionPath` lands in hm-session-vars.sh, which the generated .zshenv
# sources for non-login shells and .zprofile for login ones. So scripts and
# `zsh -c` get the tools too, not just interactive shells.
#
# Deliberately *not* sourcing the installer's nix-daemon.sh: it also exports
# NIX_PROFILES, and home-manager's own .zshrc expands that into `fpath`, which
# pulls the root profile's completion directory in. That directory's ownership
# makes compinit prompt "insecure directories … [y/n]" and hangs the shell
# before the prompt appears (tests/smoke.py catches this). PATH is all that is
# actually missing — NIX_SSL_CERT_FILE is unnecessary on a multi-user install,
# where the daemon does the fetching.
{ config, ... }:
{
  # profileDirectory is ~/.nix-profile: home-manager's own packages. The
  # default profile is where the installer put `nix` itself.
  home.sessionPath = [
    "${config.home.profileDirectory}/bin"
    "/nix/var/nix/profiles/default/bin"
  ];
}
