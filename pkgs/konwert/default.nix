{ stdenv, fetchurl, bash, perl, which
}:

let
  versionParts = builtins.split "patch" version;
  versionMain = builtins.elemAt versionParts 0;
  versionPatch = builtins.elemAt versionParts 2;	# idx 2, not idx 1 which is an empty list for the separator
  version = "1.8patch13";
in

stdenv.mkDerivation rec {

  name = "konwert-${version}";

  src = fetchurl {
    url = "mirror://debian/pool/main/k/konwert/konwert_${versionMain}.orig.tar.gz";
    sha256 = "152d4ba63e61949502f3d3305a700308cf938118d232834c67365acbcba32d32";
  };

  buildInputs = [
    bash	# interpreter of aux/fixmanconfig called by the build script
    perl	# interpreter of devel/fixtrsutf8 called by the build script
    which	# employed by the package build script
  ];

  prePatch = let
    debian = fetchurl {
      url = "mirror://debian/pool/main/k/konwert/konwert_${versionMain}-${versionPatch}.debian.tar.xz";
      sha256 = "96cf49b217b4ca32b3c0553008748284da37735c398e9b5a2e4034281fde2c8b";
    };
  in ''
    tar xJf "${debian}"
    patches="$patches $(cat debian/patches/series | sed 's|^|debian/patches/|')"
  '';

  makeFlagsArray = [ "prefix=$(out)" ];

  preInstall = ''
    patchShebangs ./aux	# ./aux/fixmanconfig must be patched also before make install, not after that by default
  '';

  meta = with stdenv.lib; {
    description = "Charset conversion for files or terminal I/O";
    homepage = http://packages.qa.debian.org/konwert;
    license = licenses.gpl2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
