# One line per machine — this is the deliberately explicit, hand-curated
# list the dendritic pattern's own docs recommend keeping explicit (unlike
# the aspect files under modules/, which auto-import — see
# parts/aspects.nix). Adding a new host is: write hosts/<name>.nix (and, for
# a real NixOS box, a hosts/<name>/ dir with hardware-configuration.nix),
# then add one line here.
{...}: {
  imports = [
    ../hosts/mochi.nix
    ../hosts/acai.nix
    ../hosts/mochi-guest.nix
    ../hosts/hm-foreign.nix
    ../hosts/jetson-hm-foreign.nix
  ];
}
