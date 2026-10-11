# The actual dendritic auto-import: every file under modules/nixos and
# modules/home is a top-level flake-parts module contributing to
# `flake.modules.nixos.<name>` / `flake.modules.homeManager.<name>` (see
# parts/flake-parts-setup.nix for what enables that option). Drop a new
# aspect file in either directory and it's immediately referenceable from
# any hosts/*.nix composition file as `config.flake.modules.<class>.<name>`
# — nothing else to wire up.
{inputs, ...}: {
  imports = [
    (inputs.import-tree ../modules/nixos)
    (inputs.import-tree ../modules/home)
  ];
}
