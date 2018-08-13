{ stdenv, fetchurl
, perl
}:

let
  version = "27";
in

stdenv.mkDerivation rec {

  name = "ctstream-${version}";

  src = fetchurl {
    url = "http://xpisar.wz.cz/ctstream/ctstream-${version}";
    sha256 = "63af4a1895f893fda435cb5e18b6a0430c8212105133326d50f328fab5e448fd";
  };

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 ${src} $out/bin/ctstream
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${src} file is not writable
    substituteInPlace $out/bin/ctstream \
      --replace /usr/bin/perl ${perl}/bin/perl
  '';

  meta = with stdenv.lib; {
    description = "Czech Television RTMP URL extractor";
    homepage = http://xpisar.wz.cz/;
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
