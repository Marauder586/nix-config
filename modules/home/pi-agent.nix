# Pi via agent-harness (see its README). Importing this turns it on:
# `pi` runs in an OpenShell sandbox, `pi-unleashed` runs unsandboxed on the
# host and also loads claude-bridge, which uses this machine's ~/.claude
# login, so no credential enters the sandbox. agent-harness also runs the
# OpenShell gateway (user service `openshell-gateway`), loads the project's
# dev shell (.envrc/flake) into the sandbox, and keeps sandboxed sessions.
{ inputs, ... }: {
  flake.modules.homeManager.pi-agent = {
    imports = [ inputs.agent-harness.modules.homeManager.agent-harness ];

    programs.agent-harness = {
      openshell.engine = "podman";
      harnesses.pi = {
        enable = true;
        command = "pi";
        skills = [
          "commit-message"
          "gitlab"
          "frontend-design"
          "impeccable"
          "caveman"
          "reverse-engineer-anything"
        ];
        extensions = [
          "ws-edit"
          "mcp-adapter"
          "subagents"
          "ask-user-question"
          "turn-timestamp"
          "superpowers"
        ];
        mcpServers = [
          "playwright"
          "rea"
        ];
        host = {
          enable = true;
          command = "pi-unleashed";
          extensions = [ "claude-bridge" ];
        };
      };

      llm = {
        providers.deepadam = {
          displayName = "DeepAdam";
          baseUrl = "http://10.50.0.125:8888/v1"; # OpenAI-compatible (vLLM/SGLang)
          # apiKeyFile = "/home/marauder/.config/agent-harness/sparks.key"; # or omit: no key
          models = [
            {
              id = "GLM-5.3-Flash";
              name = "GLM 5.3";
              reasoning = true;
              contextWindow = 104857;
              maxTokens = 131072;
            }
            {
              id = "Qwen3.8-Flash-Next";
              name = "QFN";
              reasoning = true;
              contextWindow = 104857;
              maxTokens = 131072;
            }
          ];
          # How the server takes the thinking toggle, if Pi's
          # auto-detection gets it wrong:
          # compat.thinkingFormat = "qwen-chat-template";
        };
        default = {
          provider = "deepadam";
          model = "Qwen3.8-Flash-Next";
        };
      };

      # The host's Nix-installed tools (including `nix`) in the sandbox,
      # from the host's /nix/store, mounted read-only.
      hostTools.enable = true;

      # What Nix in the sandbox fetches with agent-harness's writable store
      # (nixStore.overlay): binary caches (cache.nixos.org and any Cachix
      # cache), nixpkgs channels, GitHub (flake inputs, archives, release
      # assets, raw files, git), and the tarballs.nixos.org source mirror.
      # Plain hostname endpoints with `tls = "skip"`: no TLS inspection, so
      # tools that ship their own CA bundle (curl and git in fixed-output
      # builds) still connect, at the cost of no per-request rules. Only
      # Nix and the fetchers it runs may use them.
      network.policies.nix-fetch = {
        endpoints =
          map
            (host: {
              inherit host;
              port = 443;
              tls = "skip";
            })
            [
              "cache.nixos.org"
              "channels.nixos.org"
              "releases.nixos.org"
              "tarballs.nixos.org"
              "cachix.org"
              "*.cachix.org"
              "github.com"
              "api.github.com"
              "codeload.github.com"
              "raw.githubusercontent.com"
              "objects.githubusercontent.com"
              "release-assets.githubusercontent.com"
            ];
        binaries = [
          { path = "/nix/store/*-nix-*/bin/nix"; }
          # fetchurl, fetchzip, fetchFromGitHub
          { path = "/nix/store/*-curl-*/bin/curl"; }
          # fetchgit
          { path = "/nix/store/*-git-*/bin/git"; }
          { path = "/nix/store/*-git-*/libexec/git-core/git-remote-http*"; }
        ];
      };

      # crates.io downloads: the crate files (static.crates.io) and the
      # sparse index. Nix's Rust fetchers use them (fetchCargoVendor with
      # Python requests; importCargoLock and fetchCrate with curl), and so
      # does cargo when the agent runs it. The crates.io API host is left
      # out on purpose: it serves publish, yank, owner and login, and no
      # download needs it. Plain hostname endpoints with `tls = "skip"`,
      # like nix-fetch.
      network.policies.crates-io = {
        endpoints =
          map
            (host: {
              inherit host;
              port = 443;
              tls = "skip";
            })
            [
              "static.crates.io"
              "index.crates.io"
            ];
        binaries = [
          # fetchCargoVendor
          { path = "/nix/store/*-python3-*/bin/python3*"; }
          # importCargoLock, fetchCrate
          { path = "/nix/store/*-curl-*/bin/curl"; }
          # cargo: bin/cargo is a wrapper script; the executable that
          # connects is .cargo-wrapped.
          { path = "/nix/store/*-cargo-*/bin/cargo"; }
          { path = "/nix/store/*-cargo-*/bin/.cargo-wrapped"; }
        ];
      };

      # Nix in the sandbox: use the nix-community Cachix cache, and the
      # caches and settings a flake's nixConfig asks for (Nix runs there as
      # the owner of its own store, so it may). Appended to the store
      # settings agent-harness sets.
      harnesses.pi.environment.NIX_CONFIG = ''
        accept-flake-config = true
        extra-substituters = https://nix-community.cachix.org
        extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
      '';

      # Hindsight memory; the server stays stopped until llm.default is set.
      hindsight = {
        enable = true;
        maxParallelRetains = 1;
        dashboard.enable = true;
        mentalModelRefreshLLMMaxConcurrent = 1;
        llmMaxConcurrent = 2;
        workerMaxSlots = 2;
        workers = 1;
      };
    };
  };
}
