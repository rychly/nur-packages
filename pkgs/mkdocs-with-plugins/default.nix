{ stdenv, mkdocs
, pythonPackages
, plugins
}:

let

  unwrapped = mkdocs;

in if plugins == [] then unwrapped
  else import ./wrapper.nix {
    inherit stdenv pythonPackages plugins;
    mkdocs = unwrapped;
  }
