# Clients for homelab tools. Importing this is what turns it on for a host.
{...}: {
  flake.modules.homeManager.homelab-clients = {pkgs, ...}: {
    home.packages = with pkgs; [
      # The VPN client
      tailscale

      # Other clients
      jellyfin-tui
    ];
  };
}
