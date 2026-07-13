# Home-manager entry point.
# All configuration lives in modules/home/.
# Toggle features in features.nix.
{ ... }: {
  imports = [
    ./modules/home/core.nix

    ./modules/home/coding-agent
    ./modules/home/communication.nix
    ./modules/home/desktop.nix
    ./modules/home/development.nix
    ./modules/home/gaming.nix
    ./modules/home/hacking.nix
    ./modules/home/homelab-clients.nix
    ./modules/home/k8s.nix
    ./modules/home/monitoring.nix
    ./modules/home/virtualization.nix
  ];

  home.username = "marauder";
  home.homeDirectory = "/home/marauder";
  home.stateVersion = "26.05";
}
