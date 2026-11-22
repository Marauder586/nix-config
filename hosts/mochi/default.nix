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

  # ── USB LCD panel (Thermaltake / XinWeiYe 264a:2343) ──────
  # ttlcd drives the panel as a systemd user service (it starts at login)
  # and serves its web UI on http://127.0.0.1:7070. The module also
  # installs the udev rule that lets the logged-in user open the device.
  services.ttlcd = {
    enable = true;
    # Only used on first start; afterwards the daemon restores whatever
    # mode it was last showing.
    mode = "pet_cat";
    pet.coat = "black";
    pet.environment = "library";
    # Drive the RAM and fan lighting through the OpenRGB server enabled
    # above. Without `lights.color` the lights follow the screen's colour.
    lights.enable = true;
    # Saddle brown. LEDs cannot show a true brown (it is a dark orange),
    # so expect a dim amber; raise the values for a brighter tone.
    lights.color = "#8b4513";
  };

  system.stateVersion = "26.05";
}
