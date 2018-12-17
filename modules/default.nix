{ ... }:

let

  module-list = [
    ./bluez-alsa.nix
    ./boot.nix
    ./gui.nix
    ./hardware.nix
    ./machine.nix
    ./mc.nix
    ./mount.nix
    ./multi-glibc-locale-paths.nix
    ./printing.nix
    ./security-nss.nix
    ./spell-dicts.nix
    ./unified-gtk-qt-theme.nix
    ./users.nix
  ];

  nameFromPath = path: builtins.head (builtins.match ".*/(.*)\.nix" (toString path));

in

  builtins.listToAttrs (map (path: { name = "${nameFromPath path}"; value = import path; }) module-list)
