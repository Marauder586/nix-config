# User-space virtual machine management tools.
# Pairs with modules/nixos/virtualization.nix (system daemon).
# Importing this is what turns it on for a host.
{...}: {
  flake.modules.homeManager.virtualization = {pkgs, ...}: {
    home.packages = with pkgs; [
      gnome-boxes # GNOME VM manager GUI
      dnsmasq # DNS/DHCP for VM networking
      phodav # WebDAV for VM file sharing (spice-webdavd)
    ];
  };
}
