# Always-on base NixOS configuration: locale, nix settings, containers, and
# the universal xdg-portal fallback. Every real NixOS host imports this
# (see hosts/*.nix) — there's no flag, importing it is what turns it on.
{...}: {
  flake.modules.nixos.core = {pkgs, ...}: {
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
    # *backend* is registered for the running session — GNOME needs
    # xdg-desktop-portal-gnome, Hyprland needs xdg-desktop-portal-hyprland.
    # Those are added by modules/nixos/desktop.nix and hyprland.nix
    # respectively, and merge into this option automatically (NixOS list/
    # attrset options merge across every module that sets them) — this
    # base aspect only needs to know about the universal gtk fallback.
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };
    environment.pathsToLink = ["/share/xdg-desktop-portal" "/share/applications"];
  };
}
