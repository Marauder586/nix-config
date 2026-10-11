# hm-foreign — home-manager standalone on any non-NixOS Linux (Debian,
# Ubuntu, WSL, Pop!_OS, Mint, …). CLI-only: this host simply doesn't import
# any GUI-producing aspect (desktop, hyprland, communication, gaming,
# virtualization, modeling) — there's no flag to double-check, the aspect
# list below *is* the feature set.
#
# Username and home directory are read from $USER / $HOME at switch time so
# a single output works for any login. Requires --impure.
# Rebuild: home-manager switch --flake .#hm-foreign --impure
{
  inputs,
  config,
  ...
}: {
  flake.homeConfigurations.hm-foreign = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [config.flake.overlays.unstable];
    };
    extraSpecialArgs = {inherit inputs;};
    modules = [
      inputs.stylix.homeManagerModules.stylix
      config.flake.modules.homeManager.core
      config.flake.modules.homeManager.development
      config.flake.modules.homeManager.k8s
      config.flake.modules.homeManager.monitoring
      ({
        lib,
        pkgs,
        ...
      }: let
        user = builtins.getEnv "USER";
        home = builtins.getEnv "HOME";
      in {
        home.username =
          if user != ""
          then user
          else throw "USER env var is empty — re-run with --impure from an interactive shell.";
        home.homeDirectory =
          if home != ""
          then home
          else throw "HOME env var is empty — re-run with --impure from an interactive shell.";
        home.stateVersion = "26.05";

        # Git identity — overrides core.nix defaults for this host
        programs.git.settings.user = lib.mkForce {
          name = "example";
          email = "example@example.com";
        };

        # Stylix: Catppuccin Mocha — auto-themes all enabled programs
        stylix.enable = true;
        stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        stylix.image = ../comfy-home.png;
        stylix.autoEnable = true;
      })
    ];
  };
}
