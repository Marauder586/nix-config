# ============================================================
# Feature Toggles — hm-foreign (any non-NixOS Linux: Debian, Ubuntu, WSL…)
# ============================================================
# System features (desktop/audio/virtualization/gaming/ai/tailscale) are
# NixOS-only and have no effect here; they are kept for schema consistency.
# Rebuild: home-manager switch --flake .#hm-foreign --impure
# ============================================================
{
  # ── System features (NixOS only — no-ops here) ───────────
  desktop = false;
  audio = false;
  virtualization = false;
  gaming = false;
  localAi = false;
  homelab-clients = false;

  # ── User features (home-manager) ─────────────────────────
  hyprland = false; # Wayland compositor — GUI, not available headless
  development = true; # Helix + LSPs + network tooling (all terminal)
  communication = false; # Signal + Vesktop are GUI apps
  monitoring = true; # htop / iotop / strace / pciutils etc. (all terminal)
  remoteAi = false; # Claude Code
  k8sUtil = false; # kubectl + k9s

  # opencode + aider + goose + crush wired to Gemini for dev work only —
  # no ComfyUI / OpenSCAD / Blender / MeshLab on a headless foreign-Linux box.
  # Set GEMINI_API_KEY in the shell env (sops/agenix or ~/.zshenv) before use.
  codingAgent = {
    enable = true;
    agents = {
      coder = true;
      researcher = true;
      artist = false;
      modeler = false;
      pipeline = false;
    };
    provider = "gemini";
  };
}
