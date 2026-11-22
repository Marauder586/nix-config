# Machine-specific configuration for "cherry"
# Hardware, boot, hostname, and user account live here.
# Shared behaviour is in modules/nixos/.
{
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Boot ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── Identity / network ────────────────────────────────────
  networking.hostName = "cherry";
  # Normally comes from nixos.desktop; needed here for wifi/nmtui.
  networking.networkmanager.enable = true;

  # ── Theming ───────────────────────────────────────────────
  # Required by homeManager.core (delta colours); see hosts/cherry.nix.
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  stylix.image = ../../comfy-home.png;

  # nixos.core enables xdg.portal; without a desktop aspect nothing picks a
  # backend, so give it the default to silence the evaluation warning.
  xdg.portal.config.common.default = "*";

  # ── Users ─────────────────────────────────────────────────
  users.users.marauder = {
    isNormalUser = true;
    description = "marauder";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  system.stateVersion = "26.05";
}
