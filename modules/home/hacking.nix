# WiFi / password-cracking security tooling.
# Importing this is what turns it on for a host.
{...}: {
  flake.modules.homeManager.hacking = {pkgs, ...}: {
    home.packages = with pkgs; [
      # WiFi
      aircrack-ng
      angryoxide
      kismet
      nmap
      iw

      # Password cracking
      hashcat
    ];
  };
}
