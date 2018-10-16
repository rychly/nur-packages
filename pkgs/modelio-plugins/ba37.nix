{ stdenv, requireFile, dpkg
}:

let
  version = "3.7.1build201803142330";	# from dpkg:/control file, Version attribute
  fileName = "modelio-3.7.1-BA.deb";
  sha256 = "1pyvl3g17fzzhfzbwfy9yhj2llm5q4b3rskiiqrc0hgpm1w47xfa";	# by nix-prefetch-url --type sha256 file://${fileName}
in

import ./common.nix {
  abbr = "BA";
  description = "A set of dedicated features of Modelio for business analysts and enterprise architects";
  homepage = https://www.modeliosoft.com/en/products/modelio-ba-system-architects.html;
  inherit version fileName sha256;
  inherit stdenv requireFile dpkg;
}
