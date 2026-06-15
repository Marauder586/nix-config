{
  description = "Modular NixOS / home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    helix.url = "github:helix-editor/helix/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix/release-26.05";
    nix-colors.url = "github:misterio77/nix-colors";

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-flatpak,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

    # Build specialArgs/extraSpecialArgs for a given host features file
    mkArgs = featuresFile: {
      inherit inputs pkgs-unstable;
      features = import featuresFile;
    };

    # Build a NixOS system with stylix + home-manager wired in
    mkNixosSystem = {
      hostDir,
      featuresFile,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = mkArgs featuresFile;
        modules = [
          hostDir
          nix-flatpak.nixosModules.nix-flatpak
          inputs.stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = mkArgs featuresFile;
            home-manager.users.marauder = import ./home.nix;
          }
        ];
      };
  in {
    # ── NixOS systems ──────────────────────────────────────────
    nixosConfigurations.mochi = mkNixosSystem {
      hostDir = ./hosts/mochi;
      featuresFile = ./hosts/mochi/features.nix;
    };

    nixosConfigurations.mochi-guest = mkNixosSystem {
      hostDir = ./hosts/mochi-guest;
      featuresFile = ./hosts/mochi-guest/features.nix;
    };

    # ── Non-NixOS homes (home-manager standalone) ──────────────
    # Foreign = any non-NixOS Linux (Debian/Ubuntu/WSL/etc.) running Nix as
    # a package manager with home-manager on top.
    #
    # Username and home directory are read from $USER / $HOME at switch
    # time so a single output works for any login (marauder, ubuntu, debian,
    # nick, …). This requires --impure because pure-eval can't read env.
    #
    # Rebuild: home-manager switch --flake .#hm-foreign --impure
    homeConfigurations.hm-foreign = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = mkArgs ./hosts/hm-foreign/features.nix;
      modules = [
        inputs.stylix.homeManagerModules.stylix
        ./hosts/hm-foreign/home.nix
        ({...}: let
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
        })
      ];
    };
  };
}
