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
