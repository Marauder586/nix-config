# Helix editor (with language servers) and network/debug tooling.
# Controlled by: features.development, features.remoteAi
{
  pkgs,
  pkgs-unstable,
  lib,
  features,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf features.hacking {
      home.packages = (with pkgs; [
        # WiFi
        aircrack-ng
        angryoxide
        kismet
        nmap
        iw

        # Password cracking
        hashcat
      ]) ++ (with pkgs-unstable; [
        
      ]);
    })
  ];
}
