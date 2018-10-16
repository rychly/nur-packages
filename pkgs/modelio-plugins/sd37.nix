{ stdenv, requireFile, dpkg
}:

let
  version = "3.7.1build201803142330";	# from dpkg:/control file, Version attribute
  fileName = "modelio-3.7.1-SD.deb";
  sha256 = "11h8ika43k4w8r1g827p905hvcr5cgksp2s7p6li5fgyxvcmbbqw";	# by nix-prefetch-url --type sha256 file://${fileName}
in

import ./common.nix {
  abbr = "SD";
  description = "A set of dedicated features of Modelio for software developers";
  homepage = https://www.modeliosoft.com/en/products/modelio-sd-system-architects.html;
  inherit version fileName sha256;
  inherit stdenv requireFile dpkg;
}
