# Gaming launchers. Importing this is what turns it on for a host.
{...}: {
  flake.modules.homeManager.gaming = {pkgs, ...}: {
    home.packages = with pkgs; [
      prismlauncher
    ];
  };
}
