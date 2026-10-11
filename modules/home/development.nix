# Helix editor (with language servers) and network/debug tooling.
# Importing this is what turns it on for a host — see also
# modules/home/helix/default.nix (imported here) and
# modules/home/remote-ai.nix (Claude Code, a separate aspect).
{config, ...}: {
  flake.modules.homeManager.development = {pkgs, ...}: {
    imports = [config.flake.modules.homeManager.helix];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.packages =
      (with pkgs; [
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
      ])
      ++ (with pkgs.unstable; [
        # Rust
        rustc
        cargo
        gcc
      ])
      ++ [
        # huggingface-cli, built via uv2nix from pkgs/huggingface-cli
        # (bump with `uv lock` there — see parts/packages.nix for the build).
        config.flake.packages.${pkgs.stdenv.hostPlatform.system}.huggingface-cli
      ];
  };
}
