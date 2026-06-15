# Home-manager entry point.
# All configuration lives in modules/home/.
# Toggle features in features.nix.
{...}: {
  imports = [
    ./modules/home/core.nix
    ./modules/home/desktop.nix
    ./modules/home/development.nix
    ./modules/home/communication.nix
    ./modules/home/monitoring.nix
    ./modules/home/virtualization.nix
    ./modules/home/k8s.nix
    ./modules/home/coding-agent
  ];

  home.username = "marauder";
  home.homeDirectory = "/home/marauder";
  home.stateVersion = "26.05";
}
