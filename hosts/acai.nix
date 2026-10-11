# acai — physical Intel workstation. GNOME desktop, audio, gaming,
# homelab clients. No local AI, no virtualization host, no Claude Code.
# Rebuild: sudo nixos-rebuild switch --flake .#acai
{
  inputs,
  config,
  ...
}: {
  flake.nixosConfigurations.acai = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules = [
      ./acai
      {nixpkgs.overlays = [config.flake.overlays.unstable];}

      config.flake.modules.nixos.core
      config.flake.modules.nixos.desktop
      config.flake.modules.nixos.audio
      config.flake.modules.nixos.gaming
      config.flake.modules.nixos.networking

      inputs.nix-flatpak.nixosModules.nix-flatpak
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
            config.flake.modules.homeManager.development
            config.flake.modules.homeManager.communication
            config.flake.modules.homeManager.desktop-apps
            config.flake.modules.homeManager.desktop
            config.flake.modules.homeManager.gaming
            config.flake.modules.homeManager.k8s
            config.flake.modules.homeManager.monitoring
            config.flake.modules.homeManager.modeling
            config.flake.modules.homeManager.hacking
            config.flake.modules.homeManager.homelab-clients
          ];
          home.username = "marauder";
          home.homeDirectory = "/home/marauder";
          home.stateVersion = "26.05";
        };
      }
    ];
  };
}
