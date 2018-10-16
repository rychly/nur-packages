{ stdenv, requireFile, dpkg
}:

let
  version = "3.6.1build201703061558";	# from dpkg:/control file, Version attribute
  fileName = "modelio-3.6.1-sd.deb";
  sha256 = "1d4577jkif0k6rgppmxzaygf8absf5996ri44isfydsjf8pmf00k";	# by nix-prefetch-url --type sha256 file://${fileName}
in

import ./common.nix {
  abbr = "SD";
  description = "A set of dedicated features of Modelio for software developers";
  homepage = https://www.modeliosoft.com/en/products/modelio-sd-system-architects.html;
  inherit version fileName sha256;
  inherit stdenv requireFile dpkg;
}
