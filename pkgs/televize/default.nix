{ stdenv, fetchurl
, wget, ctstream
}:

let
  version = "26";
in

stdenv.mkDerivation rec {

  name = "televize-${version}";

  src = fetchurl {
    url = "http://xpisar.wz.cz/televize/televize-${version}";
    sha256 = "09d8706613e158f55814e667561f0d320617012a945a7b4894dc87e7af424291";
  };

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 ${src} $out/bin/televize
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${src} file is not writable
    substituteInPlace $out/bin/televize \
      --replace wget "${wget}/bin/wget" \
      --replace ctstream "${ctstream}/bin/ctstream"
  '';

  meta = with stdenv.lib; {
    description = "A script with built-in list of online TV streams";
    homepage = http://xpisar.wz.cz/;
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
