# Tailscale VPN daemon. Importing this is what turns it on for a host.
{...}: {
  flake.modules.nixos.networking = {
    services.tailscale.enable = true;
  };
}
