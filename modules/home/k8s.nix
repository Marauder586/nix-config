# Kubernetes utilities. Importing this is what turns it on for a host.
{...}: {
  flake.modules.homeManager.k8s = {pkgs, ...}: {
    home.packages = with pkgs; [
      skopeo
      kubectl
      k9s
      kubernetes-helm
    ];
  };
}
