{ stdenv, fetchurl, unzip }:

rec {

  # adapted from https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/libraries/hunspell/dictionaries.nix
  # added support for thes and hyphen and refactored, see https://github.com/gentoo/gentoo/blob/master/eclass/myspell-r2.eclass
  mkDict =
  { name, dictFiles, thesFiles, hyphFiles, readmeFile, ... }@args:
  stdenv.mkDerivation (rec {
    inherit name;
    installPhase = ''
      runHook preInstall
      # hunspell dict (*.dic, *.aff)
      install -d -m 755 "$out/share/myspell/dicts"
      for I in ${builtins.concatStringsSep " " dictFiles}; do
        install -D -m 444 -t "$out/share/hunspell/" "$I"
        ln -sv "$out/share/hunspell/$I" "$out/share/myspell/dicts/"
      done
      # hunspell thes (th_*_v*.dat, th_*_v*.idx)
      for I in ${builtins.concatStringsSep " " thesFiles}; do
        install -D -m 444 -t "$out/share/mythes/" "$I"
        ln -sv "$out/share/mythes/$I" "$out/share/myspell/"
      done
      # hunspell hyphen (hyph_*.dic)
      for I in ${builtins.concatStringsSep " " hyphFiles}; do
        install -D -m 444 -t "$out/share/hyphen/" "$I"
        ln -sv "$out/share/hyphen/$I" "$out/share/myspell/"
      done
      # docs
      install -D -m 444 "${readmeFile}" "$out/share/doc/${name}.txt"
      runHook postInstall
    '';
  } // args);

  mkDictFromOoa =
    { shortName, shortDescription, dictFileName, thesVersion
    , srcUrlSuffix, sha256, version }:
    mkDict rec {
      name = "hunspell-dict-${shortName}-${version}";
      dictFiles = [ "${dictFileName}.dic" "${dictFileName}.aff" ];
      thesFiles = [ "th_${dictFileName}_v${thesVersion}.dat" "th_${dictFileName}_v${thesVersion}.idx" ];
      hyphFiles = [ "hyph_${dictFileName}.dic" ];
      readmeFile = "README_en.txt";
      src = fetchurl {
        url = "mirror://sourceforge/aoo-extensions/${srcUrlSuffix}";
        inherit sha256;
      };
      buildInputs = [ unzip ];
      phases = "unpackPhase installPhase";
      sourceRoot = ".";
      unpackCmd = ''
        unzip $src ${builtins.concatStringsSep " " (dictFiles ++ thesFiles ++ hyphFiles)} ${readmeFile}
      '';
      meta = with stdenv.lib; {
        description = "Hunspell dictionary, hyphenation rules, and thesaurus for ${shortDescription} from Apache OpenOffice Extensions";
        homepage = "https://extensions.openoffice.org/en/project/dict-${shortName}";
        license = licenses.gpl2;
        #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
        platforms = platforms.all;
      };
    };

}
