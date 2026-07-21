# Helix editor (with language servers) and network/debug tooling.
# Controlled by: features.development, features.remoteAi
{
  pkgs,
  pkgs-unstable,
  lib,
  features,
  ...
}: {
  imports = lib.optionals features.development [./helix];

  config = lib.mkMerge [
    (lib.mkIf features.development {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      home.packages = (with pkgs; [
        # Network diagnostics / security tooling
        mtr
        iperf3
        dnsutils # dig + nslookup
        ldns # drill
        aria2 # multi-protocol downloader
        socat # netcat replacement
        nmap
        ipcalc
        net-tools
        git

        minicom
        dive

        # Tools for building when there is no flake.
        libtool
        autoconf
        automake
        gnum4
        gnumake
      ]) ++ (with pkgs-unstable; [
        # Rust
        rustc
        cargo
        gcc
      ]);
    })

    (lib.mkIf features.remoteAi {
      home.packages = [
        pkgs-unstable.claude-code
        pkgs.sox # required by Claude Code's /voice mode for mic capture
      ];
    })
  ];
}
