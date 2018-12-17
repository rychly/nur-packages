#!/usr/bin/env sh

exec wget -O $(dirname ${0})/default.nix https://github.com/NixOS/nixpkgs/raw/master/pkgs/tools/bluetooth/bluez-alsa/default.nix
