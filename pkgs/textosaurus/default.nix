{ stdenv, fetchurl, makeWrapper, qmake, qtbase, qtsvg, qttools }:

stdenv.mkDerivation rec {
  name = "textosaurus-${version}";
  version = "0.9.13";

  src = fetchurl {
    url = "https://github.com/martinrotter/textosaurus/archive/${version}.tar.gz";
    sha256 = "1951msa2zhb85pwnsz1yglnsy9940lflx6s7m9qv4hdf293vsn1j";
  };

  nativeBuildInputs = [ qmake ];
  buildInputs = [ makeWrapper qtbase qtsvg qttools ];

  qmakeFlags = [
    "LRELEASE=${stdenv.lib.getDev qttools}/bin/lrelease"
  ];

 postInstall = ''
    wrapProgram $out/bin/textosaurus --set QT_PLUGIN_PATH ${qtbase}/${qtbase.qtPluginPrefix}
 '';

  meta = with stdenv.lib; {
    description = "Cross-platform text editor based on Qt and Scintilla";
    homepage = https://github.com/martinrotter/textosaurus;
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
