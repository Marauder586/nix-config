# Tailscale VPN daemon.
# Controlled by: features.homelab-clients
{ lib, features, ... }:
{
  config = lib.mkIf features.homelab-clients {
    services.tailscale.enable = true;
  };
}
