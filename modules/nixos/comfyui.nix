# ComfyUI image / 3D generation backend for the mochi host.
#
# Runs the ai-dock/comfyui container under podman (matching the existing
# openai-edge-tts pattern in ai.nix) and exposes the API on
# 127.0.0.1:8188. From the mochi-guest QEMU/SLIRP makes this reachable as
# 10.0.2.2:8188 with no extra firewall work.
#
# GPU note: this host is an AMD RX 9070 XT (gfx1201 / RDNA4). ROCm support
# for gfx1201 is incomplete in mid-2026; the default container variant
# below is `latest-rocm` which works for older RDNA but may fall back to
# CPU on RDNA4. Switch to `latest-cpu` to force CPU, or to a Vulkan-based
# image once one ships. The container respects HSA_OVERRIDE_GFX_VERSION.
#
# Models, custom nodes, and outputs live under /var/lib/comfyui so they
# persist across container restarts and rebuilds.
#
# NOTE: the body below is entirely commented out (pre-existing, carried
# over from before this repo's dendritic rewrite — not disabled by this
# refactor). Importing `comfyui` on a host currently does nothing; whoever
# finishes this needs to uncomment the block below rather than re-wire a
# flag, since importing this aspect is what will turn it on.
{...}: {
  flake.modules.nixos.comfyui = {
    lib,
    pkgs,
    ...
  }: let
    # Bind-mount target on the host for persistent data.
    dataDir = "/var/lib/comfyui";

    # Container image. ai-dock images bundle PyTorch + extension manager and
    # are the most-maintained option for self-hosted ComfyUI in 2026.
    image = "ghcr.io/ai-dock/comfyui:latest-rocm";

    port = 8188;
  in {
    # # Persistent storage — models, custom_nodes, output, workflows.
    # systemd.tmpfiles.rules = [
    #   "d ${dataDir}                0755 root root - -"
    #   "d ${dataDir}/models         0755 root root - -"
    #   "d ${dataDir}/custom_nodes   0755 root root - -"
    #   "d ${dataDir}/output         0755 root root - -"
    #   "d ${dataDir}/input          0755 root root - -"
    #   "d ${dataDir}/user           0755 root root - -"
    #   "d ${dataDir}/workflows      0755 root root - -"
    # ];
    #
    # virtualisation.oci-containers.containers.comfyui = {
    #   inherit image;
    #   autoStart = true;
    #
    #   # Bind only to loopback. Reachable from the guest via QEMU SLIRP at
    #   # 10.0.2.2:${port}; any other guest must use Tailscale or an explicit
    #   # forward.
    #   ports = ["127.0.0.1:${toString port}:8188"];
    #
    #   volumes = [
    #     "${dataDir}/models:/opt/ComfyUI/models"
    #     "${dataDir}/custom_nodes:/opt/ComfyUI/custom_nodes"
    #     "${dataDir}/output:/opt/ComfyUI/output"
    #     "${dataDir}/input:/opt/ComfyUI/input"
    #     "${dataDir}/user:/opt/ComfyUI/user"
    #     "${dataDir}/workflows:/opt/ComfyUI/user/default/workflows"
    #   ];
    #
    #   environment = {
    #     # ai-dock entrypoint flags
    #     WEB_ENABLE_AUTH = "false"; # local-only bind; auth would be redundant
    #     WEB_PORT = "8188";
    #     CF_QUICK_TUNNELS = "false";
    #     AUTO_UPDATE = "false";
    #
    #     # AMD: pretend gfx1201 is gfx1200 so PyTorch ROCm picks a kernel
    #     # path that compiles. Harmless on non-AMD hosts.
    #     HSA_OVERRIDE_GFX_VERSION = "12.0.0";
    #     ROCM_PATH = "/opt/rocm";
    #
    #     # Pre-install custom nodes / models on first boot via ComfyUI-Manager.
    #     # Drop a bash array into `~/.config/comfy/install-nodes.sh` to extend.
    #     PROVISIONING_SCRIPT = "";
    #
    #     # Where the agent expects outputs.
    #     COMFYUI_OUTPUT_DIR = "/opt/ComfyUI/output";
    #   };
    #
    #   # Pass the GPU through. The renderD device path comes from kfd/dri.
    #   # Without ROCm support these are still safe to mount.
    #   extraOptions = [
    #     "--device=/dev/kfd"
    #     "--device=/dev/dri"
    #     "--group-add=video"
    #     "--group-add=render"
    #     "--security-opt=seccomp=unconfined"
    #     "--ipc=host"
    #     "--shm-size=8g"
    #   ];
    # };
    #
    # # This host's own podman runtime is enabled unconditionally by
    # # modules/nixos/core.nix, so no extra podman wiring is needed here.
    #
    # # ── Bootstrap script: ComfyUI-Manager + image-to-3D node packs ─────
    # # Run once after the container is up to install the custom nodes used
    # # by the @artist and @pipeline sub-agents. Idempotent.
    # environment.systemPackages = [
    #   (pkgs.writeShellScriptBin "comfyui-bootstrap" ''
    #     set -euo pipefail
    #     D=${dataDir}/custom_nodes
    #
    #     clone() {
    #       local url="$1" dir="$2"
    #       if [ ! -d "$D/$dir" ]; then
    #         ${pkgs.git}/bin/git clone --depth=1 "$url" "$D/$dir"
    #       else
    #         ${pkgs.git}/bin/git -C "$D/$dir" pull --ff-only || true
    #       fi
    #     }
    #
    #     # ComfyUI-Manager — node manager & dependency resolver.
    #     clone https://github.com/ltdrdata/ComfyUI-Manager ComfyUI-Manager
    #
    #     # Image-to-3D node packs.
    #     clone https://github.com/kijai/ComfyUI-Hunyuan3DWrapper ComfyUI-Hunyuan3DWrapper
    #     clone https://github.com/MrForExample/ComfyUI-3D-Pack ComfyUI-3D-Pack
    #     clone https://github.com/jtydhr88/ComfyUI-InstantMesh ComfyUI-InstantMesh
    #
    #     # Quality-of-life nodes.
    #     clone https://github.com/cubiq/ComfyUI_essentials ComfyUI_essentials
    #     clone https://github.com/rgthree/rgthree-comfy rgthree-comfy
    #     clone https://github.com/Fannovel16/comfyui_controlnet_aux comfyui_controlnet_aux
    #
    #     echo "Custom nodes pulled. Restart the container to load:"
    #     echo "  sudo systemctl restart podman-comfyui.service"
    #   '')
    # ];
  };
}
