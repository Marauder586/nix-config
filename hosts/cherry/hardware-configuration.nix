# PLACEHOLDER — replace with the output of `nixos-generate-config` on cherry:
#   nixos-generate-config --show-hardware-config > hosts/cherry/hardware-configuration.nix
# The values below exist only so the flake evaluates; they will not boot.
{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
