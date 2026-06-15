# Always-on base NixOS configuration.
# Locale, nix settings, networking, shell, and minimal system packages.
{ pkgs, ... }:
{
  # ── Nix ───────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = "nix-command flakes";

  # ── Locale / timezone ─────────────────────────────────────
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT    = "en_US.UTF-8";
    LC_MONETARY       = "en_US.UTF-8";
    LC_NAME           = "en_US.UTF-8";
    LC_NUMERIC        = "en_US.UTF-8";
    LC_PAPER          = "en_US.UTF-8";
    LC_TELEPHONE      = "en_US.UTF-8";
    LC_TIME           = "en_US.UTF-8";
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

  # ── Scren Share Settings  ─────────────────────────────────
  xdg.portal.enable = true;
  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];
}
