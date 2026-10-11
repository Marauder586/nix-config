# 3D modeling / CAD toolchain — CAD, mesh, and slicing tools for physical
# design work. Importing this is what turns it on for a host.
{...}: {
  flake.modules.homeManager.modeling = {pkgs, ...}: {
    home.packages = with pkgs; [
      openscad-unstable
      freecad
      blender
      meshlab
      f3d
      assimp
      super-slicer
    ];
  };
}
