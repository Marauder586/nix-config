# System-level enablement for the Hyprland Wayland compositor.
# Importing this is what turns Hyprland on for a host — no separate flag.
#
# mochi-guest is the only host with this imported, and it *also* imports
# desktop (GNOME/GDM). Hyprland is layered in as an additional, selectable
# GDM session — never as a replacement for GNOME — so this module must not
# touch anything under services.desktopManager / services.displayManager.gdm
# (see modules/nixos/desktop.nix for that).
{...}: {
  flake.modules.nixos.hyprland = {pkgs, ...}: {
    # `programs.hyprland.enable` on its own already:
    #   - installs Hyprland + xdg-desktop-portal-hyprland
    #   - sets xdg.portal.enable = true and registers the portal package
    #   - adds Hyprland to services.displayManager.sessionPackages, which is
    #     what makes it show up as a second session choice on the GDM login
    #     screen next to GNOME.
    programs.hyprland.enable = true;

    # Route the Hyprland session's portal requests to the hyprland backend,
    # falling back to gtk (registered unconditionally by
    # modules/nixos/core.nix). Merges into xdg.portal.config alongside
    # GNOME's own entry from modules/nixos/desktop.nix.
    xdg.portal.config.hyprland.default = ["hyprland" "gtk"];

    # ── Polkit authentication agent ──────────────────────────────────
    # Hyprland ships no session manager and therefore no polkit agent of
    # its own. GNOME's agent lives inside gnome-shell and is started by
    # gnome-session — it does not run under a Hyprland session even though
    # GNOME is installed on this host, so we still need a standalone agent.
    #
    # Went with `polkit_gnome` (a small GTK2 agent, launched from
    # home-manager's exec-once — see modules/home/hyprland/default.nix)
    # over the Hyprland project's own `hyprpolkitagent`: the latter pulls
    # in a full Qt6/KDE-Frameworks closure (kirigami, qqc2-desktop-style,
    # qtmultimedia, …) for a single background dialog, which doesn't fit a
    # repo that otherwise has zero Qt/KDE footprint and is already
    # GTK-themed everywhere else (GNOME, GTK portal, Firefox/GTK apps).
    #
    # `security.polkit.enable` is already forced on by
    # services.desktopManager.gnome.enable, but this module shouldn't rely
    # on GNOME being present to do its job, so set it explicitly too.
    security.polkit.enable = true;

    # Hyprlock needs a PAM service to authenticate directly — without it,
    # it falls back to (broken) `su` behaviour. Home Manager's
    # programs.hyprlock module can't create this itself (it's a NixOS-only
    # option), so it's declared here alongside the rest of the system-level
    # Hyprland wiring.
    security.pam.services.hyprlock = {};
  };
}
