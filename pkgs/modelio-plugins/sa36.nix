{ stdenv, requireFile, dpkg
}:

let
  version = "3.6.1build201703061558";	# from dpkg:/control file, Version attribute
  fileName = "modelio-3.6.1-sa.deb";
  sha256 = "07bnc23f9s2abzg1jrzh12jiv1majzvh1bf2ha2bb1bbps2vlqa4";	# by nix-prefetch-url --type sha256 file://${fileName}
in

import ./common.nix {
  abbr = "SA";
  description = "A set of dedicated features of Modelio for system, software and embedded software architects";
  homepage = https://www.modeliosoft.com/en/products/modelio-sa-system-architects.html;
  inherit version fileName sha256;
  inherit stdenv requireFile dpkg;
}
