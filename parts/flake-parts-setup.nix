# Enables the `flake.modules.<class>.<name>` option (flake-parts' own
# "modules" extra — not imported by mkFlake by default). Every aspect file
# under modules/{nixos,home} publishes itself here, type-checked by class
# ("nixos" / "homeManager") so a NixOS module can't accidentally land in a
# home-manager evaluation or vice versa.
#
# flake-parts declares `flake.nixosConfigurations` itself (as a mergeable
# lazyAttrsOf), but has no equivalent for home-manager's standalone
# `homeConfigurations` — declare it the same way, mirroring flake-parts'
# own modules/nixosConfigurations.nix, so hosts/hm-foreign.nix and
# hosts/jetson-hm-foreign.nix can each contribute one entry instead of
# conflicting over an undeclared attribute.
{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.flake-parts.flakeModules.modules];

  options.flake.homeConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
    description = "Instantiated standalone home-manager configurations. Used by `home-manager switch`.";
  };
}
