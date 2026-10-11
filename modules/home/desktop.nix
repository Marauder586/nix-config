# GNOME-only home-manager config: extra apps and dconf favorites.
# Importing this is what turns GNOME's home-manager side on for a host —
# also import modules/home/desktop-apps.nix (kitty/firefox/chromium/
# thunderbird) alongside it; that's a peer aspect, not pulled in
# transitively, so a host importing *both* desktop and hyprland (which also
# wants desktop-apps) doesn't hit a diamond import.
{...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = with pkgs; [
      obsidian
      libreoffice
      gimp
      inkscape
    ];

    # Every current GNOME host (mochi, acai) also has communication and
    # gaming on, so this list is just the union, hardcoded. A future GNOME
    # host that wants fewer favorites can `lib.mkForce` this in its own
    # hosts/<name>.nix composition file.
    dconf.settings."org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "Kitty.desktop"
        "signal.desktop"
        "vesktop.desktop"
        "steam.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };
  };
}
