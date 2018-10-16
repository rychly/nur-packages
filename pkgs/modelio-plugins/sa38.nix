{ stdenv, requireFile, dpkg
}:

let
  version = "3.8.0build201810051411";	# from dpkg:/control file, Version attribute
  fileName = "modelio-system-architect-product3.8_3.8.0_all.deb";
  sha256 = "0bz407aqfbzw8mjm4bam22f9zbyd71ybi6ihvyk1g3n7h4psljgq";	# by nix-prefetch-url --type sha256 file://${fileName}
in

import ./common.nix {
  abbr = "SA";
  description = "A set of dedicated features of Modelio for system, software and embedded software architects";
  homepage = https://www.modeliosoft.com/en/products/modelio-sa-system-architects.html;
  inherit version fileName sha256;
  inherit stdenv requireFile dpkg;
}
