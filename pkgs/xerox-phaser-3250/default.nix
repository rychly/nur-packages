{ stdenv, fetchurl
}:

let
  version = "7.6.09";
in

stdenv.mkDerivation rec {

  name = "xerox-phaser-3250-${version}";

  src = fetchurl {
    url = "http://download.support.xerox.com/pub/drivers/3250/drivers/linux/ar/p3250.tar.gz";
    sha256 = "0azb68yni63abrwdx1f9iicxgjag3v8q6v6vpfpfzsc72i68x0v3";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 -t $out/share/cups/model/xerox P3250/Linux/noarch/at_opt/share/ppd/ph3250*.ppd
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Xerox Phaser 3250 Linux Driver";
    homepage = "http://www.support.xerox.com/support/phaser-3250/downloads/enus.html?operatingSystem=linux";
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
