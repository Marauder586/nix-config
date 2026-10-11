# Claude Code. Its own aspect (separate from `development`) since some
# hosts want the dev toolchain without it. Importing this is what turns it
# on for a host.
{...}: {
  flake.modules.homeManager.remote-ai = {pkgs, ...}: {
    home.packages = [
      pkgs.unstable.claude-code
      pkgs.sox # required by Claude Code's /voice mode for mic capture
    ];
  };
}
