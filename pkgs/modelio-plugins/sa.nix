{ stdenv, requireFile, dpkg
}:

let
  version = "3.7.1build201803142330";	# from dpkg:/control file, Version attribute
  sha256 = "6ffd090bd8b328afd894e14497d60f373bed9c41c002c0b6176bf007f1754f2c";
in

import ./common.nix {
  abbr = "SA";
  description = "A set of dedicated features of Modelio for system, software and embedded software architects";
  homepage = https://www.modeliosoft.com/en/products/modelio-sa-system-architects.html;
  inherit version sha256;
  inherit stdenv requireFile dpkg;
}
