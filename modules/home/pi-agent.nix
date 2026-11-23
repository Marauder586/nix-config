# Pi via agent-harness (see its README). Importing this turns it on:
# `pi` runs in an OpenShell sandbox, `pi-unleashed` runs unsandboxed on the
# host and also loads claude-bridge, which uses this machine's ~/.claude
# login, so no credential enters the sandbox. agent-harness also runs the
# OpenShell gateway (user service `openshell-gateway`), loads the project's
# dev shell (.envrc/flake) into the sandbox, and keeps sandboxed sessions.
{inputs, ...}: {
  flake.modules.homeManager.pi-agent = {
    imports = [inputs.agent-harness.modules.homeManager.agent-harness];

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
        extensions = ["ws-edit" "mcp-adapter" "subagents" "ask-user-question"];
        mcpServers = ["playwright" "rea"];
        host = {
          enable = true;
          command = "pi-unleashed";
          extensions = ["claude-bridge"];
        };
      };

      # LLM endpoints (agent-harness README, "LLM providers"). Fill in the
      # Sparks endpoint and uncomment once it is up.
      # llm = {
      #   providers.sparks = {
      #     displayName = "Sparks";
      #     baseUrl = "http://<spark-ip>:<port>/v1"; # OpenAI-compatible (vLLM/SGLang)
      #     apiKeyFile = "/home/marauder/.config/agent-harness/sparks.key"; # or omit: no key
      #     models = [
      #       {
      #         id = "<served model name, e.g. from /v1/models>";
      #         name = "GLM 5.3";
      #         reasoning = true;
      #         contextWindow = <the server's max-model-len>;
      #         maxTokens = <max output tokens>;
      #       }
      #     ];
      #     # How the server takes the thinking toggle, if Pi's
      #     # auto-detection gets it wrong:
      #     # compat.thinkingFormat = "qwen-chat-template";
      #   };
      #   default = {
      #     provider = "sparks";
      #     model = "<same id as above>";
      #   };
      # };

      # Hindsight memory; the server stays stopped until llm.default is set.
      hindsight.enable = true;
    };
  };
}
