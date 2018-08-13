{ stdenv, requireFile, dpkg
}:

let
  version = "3.7.1build201803142330";	# from dpkg:/control file, Version attribute
  sha256 = "1caf55d9eefeb912a9b9478babe76325b30d0b48f708f442469ccc41d48c0886";
in

import ./common.nix {
  abbr = "SD";
  description = "A set of dedicated features of Modelio for software developers";
  homepage = https://www.modeliosoft.com/en/products/modelio-sd-system-architects.html;
  inherit version sha256;
  inherit stdenv requireFile dpkg;
}
