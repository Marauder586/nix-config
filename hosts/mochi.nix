# mochi — physical AMD workstation. Full local stack: GNOME desktop,
# audio, virtualization, gaming, local Ollama/ComfyUI, homelab clients.
# Rebuild: sudo nixos-rebuild switch --flake .#mochi
{
  inputs,
  config,
  ...
}: {
  flake.nixosConfigurations.mochi = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules = [
      ./mochi
      {nixpkgs.overlays = [config.flake.overlays.unstable];}

      config.flake.modules.nixos.core
      config.flake.modules.nixos.desktop
      config.flake.modules.nixos.audio
      config.flake.modules.nixos.virtualization
      config.flake.modules.nixos.gaming
      config.flake.modules.nixos.ai
      config.flake.modules.nixos.comfyui
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
            config.flake.modules.homeManager.remote-ai
            config.flake.modules.homeManager.communication
            config.flake.modules.homeManager.desktop-apps
            config.flake.modules.homeManager.desktop
            config.flake.modules.homeManager.gaming
            config.flake.modules.homeManager.virtualization
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
