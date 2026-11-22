{...}: {
  flake.modules.homeManager.vesktop = {pkgs, ...}: {
    home.packages = [
      # pkgs.unstable, not plain pkgs: the main nixpkgs pin is stuck on a
      # stale 1.6.5 dev snapshot of Vesktop, several months behind the
      # 1.6.7 release this pulls in. Screen share on GNOME Wayland was
      # broken on the stale build (confirmed via journalctl: Vesktop's
      # desktopCapturer got zero sources back from the portal even after
      # the user picked one, while Firefox's own screen share worked fine
      # on the same system — i.e. a Vesktop/Electron-side bug, not a
      # portal/PipeWire/GNOME one). Revert to plain `pkgs.vesktop` if a
      # future bump of the main nixpkgs pin catches up past 1.6.7.
      pkgs.unstable.vesktop
    ];

    # NIXOS_OZONE_WL (needed for Vesktop's screen share to use the
    # xdg-desktop-portal/PipeWire path instead of a broken XWayland
    # capturer) is set system-wide in modules/nixos/desktop.nix, not here —
    # see that file for why a home-manager session variable isn't enough.

    home.file.".config/vesktop/settings/quickCss.css" = {
      source = ./catppuccin-mocha.css;
      force = true;
    };
  };
}
