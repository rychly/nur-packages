{ stdenv, fetchurl, unzip }:

let

  # adapted from https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/libraries/hunspell/dictionaries.nix
  # added support for thes and hyphen, see https://github.com/gentoo/gentoo/blob/master/eclass/myspell-r2.eclass
  mkDict =
  { name, readmeFile, dictFileName, thesVersion, ... }@args:
  stdenv.mkDerivation (rec {
    inherit name;
    installPhase = ''
      runHook preInstall
      # hunspell dicts
      install -dm755 "$out/share/hunspell"
      install -m644 ${dictFileName}.dic "$out/share/hunspell/"
      install -m644 ${dictFileName}.aff "$out/share/hunspell/"
      # myspell dicts symlinks
      install -dm755 "$out/share/myspell/dicts"
      ln -sv "$out/share/hunspell/${dictFileName}.dic" "$out/share/myspell/dicts/"
      ln -sv "$out/share/hunspell/${dictFileName}.aff" "$out/share/myspell/dicts/"
      # hunspell thes
      install -dm755 "$out/share/mythes"
      install -m644 th_${dictFileName}_v${thesVersion}.dat "$out/share/mythes/"
      install -m644 th_${dictFileName}_v${thesVersion}.idx "$out/share/mythes/"
      # hunspell hyphen
      install -dm755 "$out/share/hyphen"
      install -m644 hyph_${dictFileName}.dic "$out/share/hyphen/"
      # docs
      install -dm755 "$out/share/doc"
      install -m644 ${readmeFile} $out/share/doc/${name}.txt
      runHook postInstall
    '';
  } // args);

  mkDictFromOoa =
    { shortName, shortDescription, dictFileName, thesVersion
    , srcUrlSuffix, sha256, version }:
    mkDict rec {
      inherit dictFileName thesVersion;
      name = "hunspell-dict-${shortName}-${version}";
      readmeFile = "README_en.txt";
      src = fetchurl {
        url = "mirror://sourceforge/aoo-extensions/${srcUrlSuffix}";
        inherit sha256;
      };
      buildInputs = [ unzip ];
      phases = "unpackPhase installPhase";
      sourceRoot = ".";
      unpackCmd = ''
        unzip $src ${dictFileName}.dic ${dictFileName}.aff th_${dictFileName}_v${thesVersion}.dat th_${dictFileName}_v${thesVersion}.idx hyph_${dictFileName}.dic ${readmeFile}
      '';
      meta = with stdenv.lib; {
        description = "Hunspell dictionary, hyphenation rules, and thesaurus for ${shortDescription} from Apache OpenOffice Extensions";
        homepage = "https://extensions.openoffice.org/en/project/dict-${shortName}";
        license = licenses.gpl2;
        #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
        platforms = platforms.all;
      };
    };

in mkDictFromOoa rec {

  shortName = "cs";
  shortDescription = "Czech";
  dictFileName = "cs_CZ";
  thesVersion = "3";

  version = "2.0";
  srcUrlSuffix = "1078/0/dict-cs-${version}.oxt";
  sha256 = "0qjlj9hq1z1fg7wipxn32hxyn153rpvji8jqchr80lss64d4j5ak";

}
