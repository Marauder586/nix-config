# Machine-specific configuration for "acai"
# Hardware, boot, hostname, and user account live here.
# Shared behaviour is in modules/nixos/.
{
  pkgs,
  lib,
  features,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/virtualization.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/ai.nix
    ../../modules/nixos/comfyui.nix
    ../../modules/nixos/networking.nix
  ];

  # ── Boot ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # kvm-amd kernel module is declared in hardware-configuration.nix
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # ── Hardware ──────────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
    ];
  };

  # ── Identity ──────────────────────────────────────────────
  networking.hostName = "acai";

  # ── Users ─────────────────────────────────────────────────
  users.users.marauder = {
    isNormalUser = true;
    description = "marauder";
    extraGroups =
      ["networkmanager" "wheel"]
      ++ lib.optionals features.virtualization ["kvm" "libvirtd"];
    shell = pkgs.zsh;
  };

  # ── Acai Specific Services ───────────────────────────────
  services.xserver = {
    layout = "us";
    xkbVariant = "dvorak";
  };
  console.useXkbConfig = true;

  system.stateVersion = "26.05";
}
