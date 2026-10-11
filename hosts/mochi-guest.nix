# mochi-guest — QEMU/KVM VM guest. GNOME *and* Hyprland (selectable GDM
# sessions), talking to mochi over QEMU SLIRP for Ollama/ComfyUI.
# Rebuild: sudo nixos-rebuild switch --flake .#mochi-guest
{
  inputs,
  config,
  ...
}: {
  flake.nixosConfigurations.mochi-guest = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules = [
      ./mochi-guest
      {nixpkgs.overlays = [config.flake.overlays.unstable];}

      config.flake.modules.nixos.core
      config.flake.modules.nixos.desktop
      config.flake.modules.nixos.hyprland
      config.flake.modules.nixos.audio

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
            config.flake.modules.homeManager.hyprland
            config.flake.modules.homeManager.k8s
            config.flake.modules.homeManager.monitoring
          ];
          home.username = "marauder";
          home.homeDirectory = "/home/marauder";
          home.stateVersion = "26.05";
        };
      }
    ];
  };
}
