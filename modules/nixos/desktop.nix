# GNOME desktop environment, X11, Stylix theming, printing.
# Controlled by: features.desktop
{
  pkgs,
  lib,
  features,
  ...
}: {
  config = lib.mkIf features.desktop {
    # Display server + desktop environment
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Printing
    services.printing.enable = true;

    # Theming (Stylix — system-wide Catppuccin Mocha)
    stylix.enable = true;
    stylix.base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    stylix.image = lib.mkDefault ../../comfy-home.png;

    # Firefox system program (extensions/profile managed by home-manager)
    programs.firefox.enable = true;

    # Networking
    networking.networkmanager.enable = true;

    # Other
    services.flatpak = {
      enable = true;
      packages = ["com.bambulab.BambuStudio"];

      # Revoke network access to Bambu Studio. nix-flatpak's `overrides` is an
      # attrset keyed by app-id → section → key; list values get merged with
      # any externally-applied entries (see nix-flatpak options.nix).
      overrides."com.bambulab.BambuStudio".Context.shared = ["!network" "!ipc"];
    };
  };
}
