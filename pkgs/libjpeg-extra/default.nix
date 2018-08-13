{ stdenv, fetchurl, libjpeg
}:

let
  version = "1.5.1-2";	# check https://packages.debian.org/source/stretch/libjpeg-turbo
in

stdenv.mkDerivation rec {

  name = "libjpeg-extra-${version}";

  src = fetchurl {
    url = "mirror://debian/pool/main/libj/libjpeg-turbo/libjpeg-turbo_${version}.debian.tar.xz";
    sha256 = "1i1w3g9s6yc0j9x2006dini4a03m11dfd4d5qwjvwapcnzicjxq0";
  };

  sourceRoot = "debian/extra";

  postPatch = ''
    substituteInPlace ./Makefile \
      --replace " -o root -g root" ""	# cannot change owner
  '';

  makeFlagsArray = [ "prefix=$(out)" ];

  preInstall = ''
    substituteInPlace ./exifautotran \
      --replace jpegexiforient $out/bin/jpegexiforient \
      --replace jpegtran ${libjpeg}/bin/jpegtran
  '';

  meta = with stdenv.lib; {
    description = "Utility programs to solve the task of automatic JPEG image orientation correction by the Exif Orientation Tag";
    homepage = http://jpegclub.org/exif_orientation.html;
    license = licenses.ijg;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.all;
  };
}
