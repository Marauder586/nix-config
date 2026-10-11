# Ollama local LLM server + Open-WebUI frontend + local STT/TTS.
#
# STT: faster-whisper (built into Open WebUI, runs on CPU — switch
#      AUDIO_STT_DEVICE to "cuda" once ROCm fully supports gfx1201/RDNA4).
# TTS: openai-edge-tts container (OpenAI-compatible endpoint, Edge TTS backend).
#
# Importing this is what turns it on for a host.
{...}: {
  flake.modules.nixos.ai = {pkgs, ...}: {
    # ── Ollama ────────────────────────────────────────────────
    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama-vulkan; # AMD Vulkan GPU acceleration
      loadModels = [
        "qwen2.5-coder:7b" # primary code model — fits in 9070 XT VRAM
        "llama3.1:8b" # fast general chat
        "nomic-embed-text" # RAG document embeddings (~270 MB)
      ];
    };

    # ── Open WebUI ────────────────────────────────────────────
    services.open-webui = {
      enable = true;
      environment = {
        # STT — faster-whisper (built-in, no extra service needed)
        AUDIO_STT_ENGINE = "faster-whisper";
        # distil-small.en is ~4x faster than distil-large-v3 on CPU; English-only
        # Switch back to distil-large-v3 once ROCm supports gfx1201 and DEVICE can be "cuda"
        AUDIO_STT_MODEL = "distil-small.en";
        AUDIO_STT_DEVICE = "cpu";
        WHISPER_VAD_FILTER = "true";

        # TTS — openai-edge-tts running on localhost:5050
        AUDIO_TTS_ENGINE = "openai";
        AUDIO_TTS_OPENAI_API_BASE_URL = "http://127.0.0.1:5050/v1";
        AUDIO_TTS_OPENAI_API_KEY = "unused"; # not validated by the server
        AUDIO_TTS_MODEL = "tts-1";
        AUDIO_TTS_VOICE = "en-IE-EmilyNeural";

        # RAG — local embeddings via Ollama, no external API needed
        RAG_EMBEDDING_ENGINE = "ollama";
        RAG_EMBEDDING_MODEL = "nomic-embed-text";
        ENABLE_RAG_WEB_SEARCH = "true";
      };
    };

    # ── openai-edge-tts container ─────────────────────────────
    virtualisation.oci-containers.containers.openai-edge-tts = {
      image = "travisvn/openai-edge-tts:latest";
      ports = ["127.0.0.1:5050:5050"];
      environment = {
        DEFAULT_VOICE = "en-IE-EmilyNeural";
        DEFAULT_SPEED = "1.3";
        REQUIRE_API_KEY = "False";
      };
    };

    # Podman is the NixOS-native container runtime
    virtualisation.podman = {
      enable = true;
      dockerCompat = true; # lets oci-containers use the docker CLI shim
    };
    virtualisation.oci-containers.backend = "podman";
  };
}
