# uv2nix: builds pkgs/huggingface-cli's venv straight from its uv.lock, so
# we get the latest huggingface_hub CLI rather than whatever nixpkgs happens
# to have pinned. Run `uv lock` in that directory to bump it.
{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    hfCliWorkspace = inputs.uv2nix.lib.workspace.loadWorkspace {
      workspaceRoot = ../pkgs/huggingface-cli;
    };
    hfCliOverlay = hfCliWorkspace.mkPyprojectOverlay {
      sourcePreference = "wheel";
    };
    hfCliPythonSet =
      (pkgs.callPackage inputs.pyproject-nix.build.packages {
        python = pkgs.python313;
      }).overrideScope (
        pkgs.lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          hfCliOverlay
        ]
      );
  in {
    packages.huggingface-cli = hfCliPythonSet.mkVirtualEnv "huggingface-cli-env" hfCliWorkspace.deps.default;
  };
}
