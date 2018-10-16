{ stdenv, requireFile, dpkg
}:

let
  version = "3.7.1build201803142330";	# from dpkg:/control file, Version attribute
  fileName = "modelio-3.7.1-SA.deb";
  sha256 = "0b2gfpqhgw3b2yvc00n086ffsfrp1zb9fi71jkcaya5kv05hkzbg";	# by nix-prefetch-url --type sha256 file://${fileName}
in

import ./common.nix {
  abbr = "SA";
  description = "A set of dedicated features of Modelio for system, software and embedded software architects";
  homepage = https://www.modeliosoft.com/en/products/modelio-sa-system-architects.html;
  inherit version fileName sha256;
  inherit stdenv requireFile dpkg;
}
