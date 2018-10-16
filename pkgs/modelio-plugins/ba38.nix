{ stdenv, requireFile, dpkg
}:

let
  version = "3.8.0build201810051411";	# from dpkg:/control file, Version attribute
  fileName = "modelio-business-analyst-product3.8_3.8.0_all.deb";
  sha256 = "0592bv00856ssj3avvlk2ljzafig4pyl5iiwagzlh7y2pals8zsr";	# by nix-prefetch-url --type sha256 file://${fileName}
in

import ./common.nix {
  abbr = "BA";
  description = "A set of dedicated features of Modelio for business analysts and enterprise architects";
  homepage = https://www.modeliosoft.com/en/products/modelio-ba-system-architects.html;
  inherit version fileName sha256;
  inherit stdenv requireFile dpkg;
}
