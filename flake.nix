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

    # uv2nix: builds Python venvs straight from a uv.lock. Used for
    # pkgs/huggingface-cli, so we get the latest huggingface_hub CLI rather
    # than whatever nixpkgs happens to have pinned.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Composability ─────────────────────────────────────────
    # flake-parts: splits this flake's outputs across parts/*.nix instead of
    # one monolithic `outputs` function — each file contributes whatever
    # flake attrs it wants (flake.nixosConfigurations, perSystem.packages…).
    # import-tree: recursively auto-imports every .nix file under a
    # directory as a module. Used both for parts/ itself (drop a file in
    # parts/, it's wired in) and for modules/nixos + modules/home (drop a
    # module there, every host picks it up — behaviour is then controlled
    # purely by hosts/*/features.nix, not by hand-maintained import lists).
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
  };

  outputs = inputs @ {
    flake-parts,
    import-tree,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} (import-tree ./parts);
}
