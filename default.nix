# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:

let

  lib-custom = import ./lib { };
  pkgs-custom = import ./pkgs { inherit pkgs; };

in {

  ## The `lib`, `modules`, and `overlay` names are special

  # functions
  lib = lib-custom;

  # NixOS modules
  modules = import ./modules { };

  # nixpkgs overlays
  overlays = import ./overlays { inherit pkgs lib-custom pkgs-custom; };

} // pkgs-custom
