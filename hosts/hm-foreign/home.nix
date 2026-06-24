# Home-manager standalone config for any non-NixOS Linux running Nix as a
# package manager (Debian, Ubuntu, WSL Ubuntu/Debian, Pop!_OS, Mint, …).
# Terminal-safe modules only — no GUI apps.
# Rebuild: home-manager switch --flake .#hm-foreign --impure
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/home/core.nix
    ../../modules/home/development.nix
    ../../modules/home/monitoring.nix
    ../../modules/home/k8s.nix
  ];

  # username / homeDirectory are injected by flake.nix from $USER / $HOME
  # at switch time, so this config works for any login.
  home.stateVersion = "26.05";

  # Git identity — overrides core.nix defaults for this host
  programs.git.settings.user = lib.mkForce {
    name = "example";
    email = "example@example.com";
  };

  # Stylix: Catppuccin Mocha — auto-themes all enabled programs
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  stylix.image = ../../comfy-home.png;
  stylix.autoEnable = true;
}
