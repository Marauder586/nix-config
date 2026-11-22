# cherry — slim, headless box whose job is running Claude Code. No desktop,
# audio, gaming, AI stack or virtualization. Just the base system plus the
# Claude Code aspect (remote-ai) and the editor git/Claude shell out to.
# Rebuild: sudo nixos-rebuild switch --flake .#cherry
{
  inputs,
  config,
  ...
}: {
  flake.nixosConfigurations.cherry = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules = [
      ./cherry
      {nixpkgs.overlays = [config.flake.overlays.unstable];} # pkgs.unstable.claude-code

      config.flake.modules.nixos.core

      # Stylix is required even without a desktop: homeManager.core reads
      # config.lib.stylix.colors for the delta diff theme. The scheme is set
      # in ./cherry since nixos.desktop (which normally sets it) isn't here.
      inputs.stylix.nixosModules.stylix
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {inherit inputs;};
        home-manager.backupFileExtension = "hm.bak";
        home-manager.users.marauder = {
          imports = [
            config.flake.modules.homeManager.core
            # core sets EDITOR / git core.editor to hx; pull in just Helix
            # rather than the whole `development` toolchain.
            config.flake.modules.homeManager.helix
            config.flake.modules.homeManager.remote-ai
          ];
          home.username = "marauder";
          home.homeDirectory = "/home/marauder";
          home.stateVersion = "26.05";
        };
      }
    ];
  };
}
