# System monitoring, debugging, and hardware introspection tools.
# Importing this is what turns it on for a host.
{...}: {
  flake.modules.homeManager.monitoring = {pkgs, ...}: {
    home.packages = with pkgs; [
      # Process / resource monitors
      htop
      iotop
      iftop

      # System call / library tracing
      strace
      ltrace
      lsof

      # Hardware / kernel stats
      sysstat
      lm_sensors # sensors command
      ethtool
      pciutils # lspci
      usbutils # lsusb
    ];
  };
}
