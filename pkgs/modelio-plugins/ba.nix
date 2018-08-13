{ stdenv, requireFile, dpkg
}:

let
  version = "3.7.1build201803142330";	# from dpkg:/control file, Version attribute
  sha256 = "caf54378a8f741c0328e71ea3c16c1a5522a24f4c93bbebe83ffbb13dea0dbdf";
in

import ./common.nix {
  abbr = "BA";
  description = "A set of dedicated features of Modelio for business analysts and enterprise architects";
  homepage = https://www.modeliosoft.com/en/products/modelio-ba-system-architects.html;
  inherit version sha256;
  inherit stdenv requireFile dpkg;
}
