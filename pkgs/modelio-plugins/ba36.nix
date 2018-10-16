{ stdenv, requireFile, dpkg
}:

let
  version = "3.6.1build201703061558";	# from dpkg:/control file, Version attribute
  fileName = "modelio-3.6.1-ba.deb";
  sha256 = "1x4pcdxbf5crq6sl9hi7z9fzms19axzrd4dgyxgyggbwbdz6280d";	# by nix-prefetch-url --type sha256 file://${fileName}
in

import ./common.nix {
  abbr = "BA";
  description = "A set of dedicated features of Modelio for business analysts and enterprise architects";
  homepage = https://www.modeliosoft.com/en/products/modelio-ba-system-architects.html;
  inherit version fileName sha256;
  inherit stdenv requireFile dpkg;
}
