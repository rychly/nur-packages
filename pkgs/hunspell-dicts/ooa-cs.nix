{ stdenv, fetchurl, unzip }:

let

  common = import ./common.nix { inherit stdenv fetchurl unzip; };

in common.mkDictFromOoa rec {

  shortName = "cs";
  shortDescription = "Czech";
  dictFileName = "cs_CZ";
  thesVersion = "3";

  version = "2.0";
  srcUrlSuffix = "1078/0/dict-cs-${version}.oxt";
  sha256 = "0qjlj9hq1z1fg7wipxn32hxyn153rpvji8jqchr80lss64d4j5ak";

}
