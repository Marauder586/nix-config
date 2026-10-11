# Local-first agentic coding CLI.
#
# Primary agent: opencode (https://opencode.ai) — Claude-Code-shaped TUI that
# speaks any OpenAI-compatible endpoint, MCP servers, agents/, and command/.
#
# Companion CLIs installed alongside for variety: aider, goose, crush, codex,
# mcphost. Pick whichever fits the task.
#
# Sub-agents and slash-commands are dropped into ~/.config/opencode/ from this
# module's `agent/`, `command/`, and `skills/` directories. Each personality
# can be toggled independently — turning one off skips its packages, MCP
# servers, agent prompts, and slash commands.
#
# Importing `codingAgent` (see hosts/*.nix) is what turns this on for a
# host — there is no separate enable flag. What it does is still tunable
# per host via the `codingAgent.*` options declared below, set from that
# host's own composition file, e.g.:
#
#   config.flake.modules.homeManager.codingAgent
#   { codingAgent.provider = "gemini"; codingAgent.agents.modeler = false; }
{...}: {
  flake.modules.homeManager.codingAgent = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.codingAgent;
    inherit (cfg) agents provider;
    ollamaBaseURL = "${cfg.ollamaHost}/v1";

    # ── Default models per provider ─────────────────────────────
    # cfg.model/smartModel/smallModel are declared options (default null),
    # so `or` won't do here — null is a present value, not a missing one.
    defaultModel =
      if cfg.model != null
      then cfg.model
      else if provider == "gemini"
      then "google/gemini-2.5-flash"
      else "ollama/qwen2.5-coder:7b";
    smartModel =
      if cfg.smartModel != null
      then cfg.smartModel
      else if provider == "gemini"
      then "google/gemini-2.5-pro"
      else "ollama/qwen3.5:35b";
    smallModel =
      if cfg.smallModel != null
      then cfg.smallModel
      else if provider == "gemini"
      then "google/gemini-2.5-flash"
      else "ollama/llama3.1:8b";

    # The checked-in agent prompts hard-code Ollama model strings; rewrite
    # them per-host so the same .md works under either provider.
    renderAgent = name: let
      raw = builtins.readFile (./agent + "/${name}.md");
      rendered =
        lib.replaceStrings
        ["ollama/qwen2.5-coder:7b" "ollama/qwen3.5:35b" "ollama/llama3.1:8b"]
        [defaultModel smartModel smallModel]
        raw;
    in
      pkgs.writeText "${name}.md" rendered;

    # ── Provider blocks for opencode's `provider` config ────────
    providerConfig =
      if provider == "gemini"
      then {
        google = {
          npm = "@ai-sdk/google";
          name = "Google Gemini";
          options = {
            apiKey = "{env:GEMINI_API_KEY}";
          };
          models = {
            "gemini-2.5-pro" = {name = "Gemini 2.5 Pro";};
            "gemini-2.5-flash" = {name = "Gemini 2.5 Flash";};
          };
        };
      }
      else {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama";
          options = {
            baseURL = ollamaBaseURL;
          };
          models = {
            "qwen2.5-coder:7b" = {name = "Qwen2.5-Coder 7B";};
            "qwen3.5:35b" = {name = "Qwen3.5 35B (smart)";};
            "llama3.1:8b" = {name = "Llama 3.1 8B (fast)";};
          };
        };
      };

    # ── MCP servers — built up conditionally so disabled personalities
    #    don't drag in their backends.
    baseMcp = {
      filesystem = {
        type = "local";
        enabled = true;
        command = [
          "${pkgs.nodejs_22}/bin/npx"
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "${config.home.homeDirectory}"
        ];
      };

      fetch = {
        type = "local";
        enabled = agents.researcher;
        command = [
          "${pkgs.uv}/bin/uvx"
          "mcp-server-fetch"
        ];
      };

      searxng = {
        type = "local";
        enabled = agents.researcher;
        command = [
          "${pkgs.uv}/bin/uvx"
          "mcp-searxng"
        ];
        environment = {
          SEARXNG_URL = cfg.searxngUrl;
        };
      };

      duckduckgo = {
        type = "local";
        enabled = agents.researcher;
        command = [
          "${pkgs.uv}/bin/uvx"
          "duckduckgo-mcp-server"
        ];
      };

      playwright = {
        type = "local";
        enabled = agents.researcher;
        command = [
          "${pkgs.unstable.playwright-mcp}/bin/playwright-mcp"
          "--headless"
          "--isolated"
        ];
      };

      github = {
        type = "local";
        enabled = false; # set GITHUB_PERSONAL_ACCESS_TOKEN and flip on
        command = [
          "${pkgs.github-mcp-server}/bin/github-mcp-server"
          "stdio"
        ];
        environment = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "$GITHUB_PERSONAL_ACCESS_TOKEN";
        };
      };
    };

    comfyMcp = lib.optionalAttrs (agents.artist || agents.pipeline) {
      comfyui = {
        type = "local";
        enabled = true;
        command = [
          "${pkgs.uv}/bin/uvx"
          "comfyui-mcp-server"
        ];
        environment = {
          COMFYUI_URL = cfg.comfyuiHost;
          COMFYUI_OUTPUT_DIR = "${config.home.homeDirectory}/comfy-out";
        };
      };
    };

    opencodeConfig = {
      "$schema" = "https://opencode.ai/config.json";
      theme = "system";
      model = defaultModel;
      small_model = smallModel;
      autoshare = false;
      autoupdate = false;

      provider = providerConfig;

      agent = {
        build = {model = defaultModel;};
        plan = {model = smartModel;};
      };

      mcp = baseMcp // comfyMcp;

      experimental = {
        hint_endpoints =
          {ollama = ollamaBaseURL;}
          // lib.optionalAttrs (agents.artist || agents.pipeline) {
            comfyui = cfg.comfyuiHost;
          }
          // lib.optionalAttrs (provider == "ollama") {
            open_webui = cfg.openWebuiHost;
          };
      };
    };

    # ── aider ───────────────────────────────────────────────────
    aiderConfig =
      if provider == "gemini"
      then ''
        model: gemini/gemini-2.5-pro
        weak-model: gemini/gemini-2.5-flash
        edit-format: diff
        auto-commits: false
        dirty-commits: false
        pretty: true
        stream: true
        suggest-shell-commands: true
        show-model-warnings: false
      ''
      else ''
        # Ollama on the configured host. aider reads OLLAMA_API_BASE for ollama/* models.
        model: ollama_chat/qwen2.5-coder:7b
        weak-model: ollama_chat/llama3.1:8b
        edit-format: diff
        auto-commits: false
        dirty-commits: false
        pretty: true
        stream: true
        suggest-shell-commands: true
        show-model-warnings: false
      '';

    # ── goose ───────────────────────────────────────────────────
    gooseConfig =
      if provider == "gemini"
      then ''
        GOOSE_PROVIDER: google
        GOOSE_MODEL: gemini-2.5-pro
      ''
      else ''
        GOOSE_PROVIDER: openai
        GOOSE_MODEL: qwen2.5-coder:7b
        OPENAI_HOST: ${cfg.ollamaHost}
        OPENAI_BASE_PATH: v1/chat/completions
        OPENAI_API_KEY: ollama
      '';

    # ── crush ───────────────────────────────────────────────────
    crushConfig = {
      "$schema" = "https://charm.land/crush.json";
      providers =
        if provider == "gemini"
        then {
          google = {
            type = "google";
            name = "Google Gemini";
            api_key = "{env:GEMINI_API_KEY}";
            models = [
              {
                id = "gemini-2.5-pro";
                name = "Gemini 2.5 Pro";
                context_window = 1048576;
                default_max_tokens = 8192;
              }
              {
                id = "gemini-2.5-flash";
                name = "Gemini 2.5 Flash";
                context_window = 1048576;
                default_max_tokens = 8192;
              }
            ];
          };
        }
        else {
          ollama = {
            type = "openai";
            base_url = ollamaBaseURL;
            api_key = "ollama";
            name = "Ollama";
            models = [
              {
                id = "qwen2.5-coder:7b";
                name = "Qwen2.5 Coder 7B";
                context_window = 32768;
                default_max_tokens = 4096;
              }
              {
                id = "qwen3.5:35b";
                name = "Qwen3.5 35B";
                context_window = 32768;
                default_max_tokens = 4096;
              }
            ];
          };
        };
    };

    # ── Shell env — only set OpenAI-compat vars when the provider is local
    #    Ollama. With Gemini, aider/goose/crush each handle their own auth.
    shellEnv =
      if provider == "ollama"
      then {
        OPENAI_API_BASE = ollamaBaseURL;
        OPENAI_BASE_URL = ollamaBaseURL;
        OPENAI_API_KEY = "ollama";
        OLLAMA_API_BASE = cfg.ollamaHost;
        OLLAMA_HOST = cfg.ollamaHost;
      }
      else {};

    comfyEnv = lib.optionalAttrs (agents.artist || agents.pipeline) {
      COMFYUI_URL = cfg.comfyuiHost;
    };

    openWebUiEnv = lib.optionalAttrs (provider == "ollama") {
      OPEN_WEBUI_URL = cfg.openWebuiHost;
    };

    # ── Per-personality package sets ────────────────────────────
    coderPackages = with pkgs; [
      ripgrep
      fd
      fzf
      jq
      yq-go
      dasel
      tree
      bat
      eza
      zoxide
      delta
      hyperfine
      tokei
      gh
      just
      pandoc
      glow
      shellcheck
      shfmt
      prettier
      ruff
      black
      mypy
      alejandra
    ];

    researcherPackages = with pkgs; [
      curl
      wget
      httpie
      xh
      lynx
      w3m
      monolith
      yt-dlp
      pup
      htmlq
      python313Packages.ddgs
    ];

    # The artist's heavy lifting happens on the ComfyUI host; locally we just
    # need the MCP bridge runtime, which lives in the always-on package set.
    artistPackages = [];

    # The modeler's CAD/mesh/slicing tools (freecad, blender, …) are a
    # standalone desktop aspect — see modules/home/modeling.nix — so they
    # install independently of whether any AI agent is enabled.

    # MCP / agent runtimes that any enabled personality needs.
    alwaysPackages = with pkgs; [
      unstable.opencode
      aider-chat
      goose-cli
      crush
      mcphost

      nodejs_22
      uv
      unstable.playwright-mcp
      github-mcp-server
      mcp-proxy

      python3
      gnumake
    ];
  in {
    options.codingAgent = {
      agents = {
        coder = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        researcher = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        artist = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        modeler = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        pipeline = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
      provider = lib.mkOption {
        type = lib.types.enum ["ollama" "gemini"];
        default = "ollama";
      };
      model = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default-tier model id (provider-prefixed). Null picks a provider default.";
      };
      smartModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      smallModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      ollamaHost = lib.mkOption {
        type = lib.types.str;
        default = "http://10.0.2.2:11434";
      };
      comfyuiHost = lib.mkOption {
        type = lib.types.str;
        default = "http://10.0.2.2:8188";
      };
      openWebuiHost = lib.mkOption {
        type = lib.types.str;
        default = "http://10.0.2.2:8080";
      };
      searxngUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://searx.be";
      };
    };

    config = {
      home.packages =
        alwaysPackages
        ++ lib.optionals agents.coder coderPackages
        ++ lib.optionals agents.researcher researcherPackages
        ++ lib.optionals agents.artist artistPackages
        ++ lib.optionals agents.pipeline artistPackages;

      home.sessionVariables = shellEnv // comfyEnv // openWebUiEnv;

      # ── opencode + aider + goose + crush + per-personality drop-ins ───
      xdg.configFile = lib.mkMerge [
        {
          "opencode/opencode.json".text = builtins.toJSON opencodeConfig;
          "opencode/AGENTS.md".source = ./AGENTS.md;
          "goose/config.yaml".text = gooseConfig;
          "crush/crush.json".text = builtins.toJSON crushConfig;
        }
        (lib.mkIf agents.coder {
          "opencode/agent/coder.md".source = renderAgent "coder";
          "opencode/command/refactor.md".source = ./command/refactor.md;
          "opencode/command/review.md".source = ./command/review.md;
          "opencode/skills/coding.md".source = ./skills/coding.md;
        })
        (lib.mkIf agents.researcher {
          "opencode/agent/researcher.md".source = renderAgent "researcher";
          "opencode/command/research.md".source = ./command/research.md;
          "opencode/skills/web-research.md".source = ./skills/web-research.md;
        })
        (lib.mkIf agents.artist {
          "opencode/agent/artist.md".source = renderAgent "artist";
          "opencode/command/imggen.md".source = ./command/imggen.md;
          "opencode/skills/image-generation.md".source = ./skills/image-generation.md;
          "opencode/skills/comfyui-workflows" = {
            source = ./skills/comfyui-workflows;
            recursive = true;
          };
        })
        (lib.mkIf agents.modeler {
          "opencode/agent/modeler.md".source = renderAgent "modeler";
          "opencode/command/scad.md".source = ./command/scad.md;
          "opencode/skills/3d-modeling.md".source = ./skills/3d-modeling.md;
          "opencode/skills/meshlab-decimate-50k.mlx".source = ./skills/meshlab-decimate-50k.mlx;
          "opencode/skills/meshlab-repair.mlx".source = ./skills/meshlab-repair.mlx;
        })
        (lib.mkIf agents.pipeline {
          "opencode/agent/pipeline.md".source = renderAgent "pipeline";
          "opencode/command/img23d.md".source = ./command/img23d.md;
          "opencode/skills/image-to-3d.md".source = ./skills/image-to-3d.md;
        })
      ];

      # ── aider + ComfyUI output dir (only when artist/pipeline is on) ──
      home.file = lib.mkMerge [
        {".aider.conf.yml".text = aiderConfig;}
        (lib.mkIf (agents.artist || agents.pipeline) {
          "comfy-out/.keep".text = "";
        })
      ];
    };
  };
}
