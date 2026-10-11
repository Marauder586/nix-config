{...}: {
  flake.modules.homeManager.vesktop = {pkgs, ...}: {
    home.packages = with pkgs; [
      vesktop
    ];
    home.file.".config/vesktop/settings/quickCss.css" = {
      source = ./catppuccin-mocha.css;
      force = true;
    };
  };
}
