{ stdenv, requireFile, dpkg
}:

let
  version = "3.8.0build201810051411";	# from dpkg:/control file, Version attribute
  fileName = "modelio-software-developer-product3.8_3.8.0_all.deb";
  sha256 = "1brjw0ds101afb75mkcacxdvz9ldhf1ksnh1wniklr29r0r14w85";	# by nix-prefetch-url --type sha256 file://${fileName}
in

import ./common.nix {
  abbr = "SD";
  description = "A set of dedicated features of Modelio for software developers";
  homepage = https://www.modeliosoft.com/en/products/modelio-sd-system-architects.html;
  inherit version fileName sha256;
  inherit stdenv requireFile dpkg;
}
