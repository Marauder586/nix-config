# Makes nixpkgs-unstable reachable as `pkgs.unstable.<name>` from any
# nixpkgs instantiation, instead of threading a separate `pkgs-unstable`
# value through specialArgs (a dendritic anti-pattern — see
# https://github.com/mightyiam/dendritic#specialargs-pass-thru). Applied to
# every host via `nixpkgs.overlays` in each host's composition file
# (hosts/*.nix) — real NixOS hosts set it once at the system level and
# home-manager inherits it through `useGlobalPkgs`; foreign hosts set it
# directly when building their standalone `pkgs`.
{inputs, ...}: {
  flake.overlays.unstable = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}
