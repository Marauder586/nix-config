# ============================================================
# Feature Toggles — mochi-guest (QEMU/KVM virtual machine)
# ============================================================
# Set a flag to false to exclude that group of packages/services.
# Rebuild: sudo nixos-rebuild switch --flake .#mochi-guest
# ============================================================
{
  # ── System features (NixOS only) ─────────────────────────
  desktop = true; # GNOME desktop + X11 + Stylix theming
  audio = true; # PipeWire audio
  virtualization = false; # guests don't run nested VMs
  gaming = false; # no GPU passthrough in guest
  localAi = false; # too resource-heavy for a VM
  remoteAi = true;
  homelab-clients = false;

  # ── User features (home-manager) ─────────────────────────
  hyprland = true; # Hyprland + Alacritty + Firefox
  development = true; # Helix + 70+ LSPs + network tooling
  communication = true; # Signal Desktop + Vesktop (Discord)
  monitoring = true; # htop / iotop / sensors / strace / pciutils
  k8sUtil = true; # kubectl + k9s

  # opencode + aider + goose + crush. All personalities on; talks to mochi
  # over QEMU SLIRP for Ollama and ComfyUI.
  codingAgent = {
    enable = true;
    agents = {
      coder = true;
      researcher = true;
      artist = true;
      modeler = true;
      pipeline = true;
    };
    provider = "ollama";
    ollamaHost = "http://10.0.2.2:11434";
    comfyuiHost = "http://10.0.2.2:8188";
    openWebuiHost = "http://10.0.2.2:8080";
  };
}
