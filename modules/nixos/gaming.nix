# Steam gaming platform. Importing this is what turns it on for a host.
{...}: {
  flake.modules.nixos.gaming = {
    programs.steam.enable = true;
  };
}
