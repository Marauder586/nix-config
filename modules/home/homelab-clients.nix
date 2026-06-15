# Clients for homelab tools
{
  pkgs,
  lib,
  features,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf features.homelab-clients {
      home.packages = with pkgs; [
        # The VPN client
        tailscale

        # Other clients
        jellyfin-tui
      ];
    })
  ];
}
