# Machine-specific configuration for "mochi"
# Hardware, boot, hostname, and user account live here.
# Shared behaviour is in modules/nixos/.
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Boot ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # kvm-amd kernel module is declared in hardware-configuration.nix
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # ── Identity ──────────────────────────────────────────────
  networking.hostName = "mochi";

  # ── Users ─────────────────────────────────────────────────
  users.users.marauder = {
    isNormalUser = true;
    description = "marauder";
    extraGroups =
      ["networkmanager" "wheel"]
      ++ lib.optionals config.virtualisation.libvirtd.enable ["kvm" "libvirtd"];
    shell = pkgs.zsh;
  };

  # ── Mochi Specific Services ───────────────────────────────
  services.hardware.openrgb = { 
    enable = true; 
    package = pkgs.openrgb-with-all-plugins; 
    motherboard = "amd"; 
    server.port = 6742; 
  };

  system.stateVersion = "26.05";
}
