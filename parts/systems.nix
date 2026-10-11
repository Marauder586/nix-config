# Systems this flake builds for. Everything here is x86_64-linux today;
# add more and every perSystem block in parts/ picks them up automatically.
{...}: {
  systems = ["x86_64-linux"];
}
