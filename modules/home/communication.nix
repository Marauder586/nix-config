# Signal Desktop and Vesktop (Discord alternative).
# Importing this is what turns it on for a host.
{config, ...}: {
  flake.modules.homeManager.communication = {pkgs, ...}: {
    imports = [config.flake.modules.homeManager.vesktop];

    home.packages = with pkgs; [
      signal-desktop
    ];
  };
}
