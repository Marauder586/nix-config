# Gaming Launchers.
# Controlled by: features.gaming
{
  pkgs,
  lib,
  features,
  ...
}: {
  config = lib.mkIf features.gaming {
    home.packages = with pkgs; [
      prismlauncher
    ];
  };
}
