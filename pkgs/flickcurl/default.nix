{ stdenv, fetchFromGitHub, autoreconfHook, pkgconfig, curl, libxml2
, withGtkDoc ? true, gtk-doc ? null
, withRaptor ? false, librdf_raptor2 ? null
}:

assert withGtkDoc -> gtk-doc != null;
assert withRaptor -> librdf_raptor2 != null;

let
  libmtwist = fetchFromGitHub {
    owner = "dajobe";
    repo = "libmtwist";
    rev = "5c9b486cc27202977fb353c46d4ac8a167f370ac";	# from git submodule spec in the flickcurl repo
    sha256 = "00807w87qa5wjbszbr2n132snyxr11hfnadr4x93dy010xg7v69h";
  };
  version = "2015.06.01";
in

stdenv.mkDerivation rec {

  name = "flickcurl-${version}";

  src = fetchFromGitHub {
    owner = "dajobe";
    repo = "flickcurl";
    rev = "b2d64c8289ef519e5265a73148b650b053cc0ae6";	# on update: check also the libmtwist submodule rev above
    sha256 = "03xc8rzcvhkfh98l26qg00m7z8q9zxm0ql6qj4n1ghi1wmqjg5yl";
  };

  nativeBuildInputs = [ gtk-doc autoreconfHook pkgconfig ];
  buildInputs = [ curl libxml2 ]
    ++ stdenv.lib.optionals withRaptor [ librdf_raptor2 ];

  postPatch = ''
    # copy git submodule directory (a symlink is not enought as the source is write-protected)
    cp -r --no-preserve=mode ${libmtwist}/* libmtwist/
    # provide stubs for documentation files otherwise generated from their corresponding HTML sources by lynx with --enable-maintainer-mode configure flag
    touch NEWS README
  '' + stdenv.lib.optionalString (!withGtkDoc) ''
    # provide a stub makefile for the GTK documentation (in .gitignore, generated by ${gtk-doc}/bin/gtkdocize)
    echo "EXTRA_DIST=" > gtk-doc.make
    substituteInPlace configure.ac \
      --replace "GTK_DOC_CHECK([1.3])" ""
  '';

  preAutoreconf = ''
    gtkdocize
  '';

  configureFlags = [ "--enable-maintainer-mode" ]
    ++ stdenv.lib.optionals withRaptor [ "--with-raptor" ];

  meta = with stdenv.lib; {
    description = "Flickr C API library";
    homepage = http://librdf.org/flickcurl/;
    license = licenses.bsd2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
