# Machine-specific configuration for "mochi-guest"
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
    ../../modules/nixos/networking.nix
  ];

  # ── SPICE guest agent ─────────────────────────────────────
  # `-x` means --foreground (NOT X11 mode — the agent picks Mutter D-Bus or
  # X11 automatically). Without -x the agent daemonizes, the parent exits,
  # and Type=simple thinks the unit died on every start.
  # The cold-boot race: graphical-session.target fires before XWayland is
  # accepting connections, the agent exits status 0 with "could not connect
  # to X-server", and Restart=on-failure ignores exit-0 → auto-resize stays
  # dead until manual restart. Fixes: poll xset until X is up, then
  # Restart=always so any post-start hiccup also retries.
  services.spice-vdagentd.enable = true;
  # spice-webdavd proxies the host's SPICE shared folder onto localhost:9843.
  # GNOME/Nautilus usually auto-mounts it; if /run/user/1000/gvfs is empty
  # after login, mount manually: `gio mount dav://localhost:9843`
  # The share then appears at:
  #   /run/user/1000/gvfs/dav:host=localhost,port=9843,ssl=false/vm-share/
  services.spice-webdavd.enable = true;
  systemd.user.services.spice-vdagent = {
    description = "SPICE VD agent";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];
    environment.DISPLAY = ":0";
    serviceConfig = {
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 60); do ${pkgs.xorg.xset}/bin/xset q >/dev/null 2>&1 && exit 0; sleep 1; done; exit 1'";
      ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
      Restart = "always";
      RestartSec = 2;
      Type = "simple";
    };
  };

  # ── Boot ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # kvm-amd kernel module is declared in hardware-configuration.nix
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # ── Identity ──────────────────────────────────────────────
  networking.hostName = "mochi-guest";

  # Distinct theme so guest VM is visually distinguishable from mochi host.
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest-dark-hard.yaml";
  stylix.image = ../../everforest.jpg;

  # ── kind test cluster (kingdom.test → localhost) ──────────
  # Port-forward ingress-nginx: kubectl port-forward -n clowder-test
  #   svc/clowder-ingress-nginx-controller 8080:80 8443:443
  networking.extraHosts = ''
    127.0.0.1 forgejo.kingdom.test
    127.0.0.1 keycloak.kingdom.test
    127.0.0.1 lldap.kingdom.test
    127.0.0.1 actual.kingdom.test
  '';

  # ── USB LCD panel (Thermaltake / XinWeiYe 264a:2343) ──────
  # Give the `users` group read/write access to the panel so ttlcd can
  # run without root. TAG+="uaccess" additionally grants access to the
  # currently-logged-in user via systemd-logind ACLs.
  services.udev.extraRules = ''
    # Thermaltake / XinWeiYe 3.95" square TFT LCD (480x480)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="264a", ATTRS{idProduct}=="2343", \
      MODE="0660", GROUP="users", TAG+="uaccess"
    # Sibling SKU (128-height panel)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="264a", ATTRS{idProduct}=="233d", \
      MODE="0660", GROUP="users", TAG+="uaccess"
  '';

  # ── Users ─────────────────────────────────────────────────
  users.users.marauder = {
    isNormalUser = true;
    description = "marauder";
    extraGroups =
      ["networkmanager" "wheel" "users"]
      ++ lib.optionals features.virtualization ["kvm" "libvirtd"];
    shell = pkgs.zsh;
  };

  system.stateVersion = "26.05";
}
