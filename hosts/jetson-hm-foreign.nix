# jetson-hm-foreign — home-manager standalone on the Jetson (foreign Linux,
# no NixOS). CLI-only: no GUI-producing aspect is imported below — there's
# no flag to double-check, the aspect list below *is* the feature set.
#
# Username and home directory are read from $USER / $HOME at switch time so
# a single output works for any login. Requires --impure.
# Rebuild: home-manager switch --flake .#jetson-hm-foreign --impure
{
  inputs,
  config,
  ...
}: {
  flake.homeConfigurations.jetson-hm-foreign = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [config.flake.overlays.unstable];
    };
    extraSpecialArgs = {inherit inputs;};
    modules = [
      inputs.stylix.homeManagerModules.stylix
      config.flake.modules.homeManager.core
      config.flake.modules.homeManager.development
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

        # enable = false (no theming applied to any program), but a scheme is
        # still required: modules/home/core.nix reads config.lib.stylix.colors
        # unconditionally for the git-delta palette, which throws without one
        # even when stylix itself is off — this is a pre-existing latent bug
        # that only surfaced once this host became reachable at all (it was
        # previously wired out of flake.nix entirely, so nobody ever ran
        # `home-manager switch --flake .#jetson-hm-foreign` and hit it).
        stylix.enable = false;
        stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      })
    ];
  };
}
