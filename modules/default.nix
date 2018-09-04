{ ... }:

let

  module-list = [
    ./machine.nix
    ./mc.nix
    ./multi-glibc-locale-paths.nix
    ./security-nss.nix
    ./spell-dicts.nix
    ./unified-gtk-qt-theme.nix
  ];

  nameFromPath = path: builtins.head (builtins.match ".*/(.*)\.nix" (toString path));

in

  builtins.listToAttrs (map (path: { name = "${nameFromPath path}"; value = import path; }) module-list)
