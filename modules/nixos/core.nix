# Always-on base NixOS configuration.
# Locale, nix settings, networking, shell, and minimal system packages.
{
  pkgs,
  lib,
  features,
  ...
}: {
  # ── Nix ───────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = "nix-command flakes";

  # ── Locale / timezone ─────────────────────────────────────
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # ── Shell (required so user shell is available system-wide) ─
  programs.zsh.enable = true;

  # ── Minimal system packages ───────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  # ── Containerization Runner ───────────────────────────────
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # lets oci-containers use the docker CLI shim
  };
  virtualisation.oci-containers.backend = "podman";

  # ── Screen Share Settings ─────────────────────────────────
  # Screen sharing (Vesktop/Discord, OBS, browsers) on Wayland goes through
  # xdg-desktop-portal + PipeWire (PipeWire comes from modules/nixos/audio.nix).
  # The frontend (xdg-desktop-portal) only implements ScreenCast if a matching
  # *backend* is registered for the running session:
  #   - GNOME    → xdg-desktop-portal-gnome
  #   - Hyprland → xdg-desktop-portal-hyprland
  # We list both explicitly rather than relying on the GNOME module's implicit
  # add — without the gnome backend the ScreenCast D-Bus interface never
  # appears and Vesktop greys out the screen-share button.
  xdg.portal = {
    enable = true;
    extraPortals =
      lib.optionals features.desktop [pkgs.xdg-desktop-portal-gnome]
      ++ lib.optionals features.hyprland [pkgs.xdg-desktop-portal-hyprland]
      ++ [pkgs.xdg-desktop-portal-gtk]; # file-chooser / non-screencast fallback
    # Route each session's portals to its backend, falling back to gtk.
    # The frontend matches these keys against XDG_CURRENT_DESKTOP.
    config = {
      gnome.default = lib.mkIf features.desktop ["gnome" "gtk"];
      hyprland.default = lib.mkIf features.hyprland ["hyprland" "gtk"];
    };
  };
  environment.pathsToLink = ["/share/xdg-desktop-portal" "/share/applications"];
}
