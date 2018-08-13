{ stdenv, fetchurl, makeWrapper, makeDesktopItem
, jre
}:

let
  desktopItem = makeDesktopItem {
    name = "raccoon";
    exec = "raccoon";
    desktopName = "Raccoon ${version}";
    genericName = "Raccoon ${version}";
    comment = "Google Play Desktop client to download apps from Google Play without a phone";
    categories = "Network;Java";
  };
  version = "4.2.5";
in

stdenv.mkDerivation rec {

  name = "raccoon-${version}";

  src = fetchurl {
    url = "https://raccoon.onyxbits.de/sites/raccoon.onyxbits.de/files/raccoon-${version}.jar";
    sha256 = "1f0rarzn9bky6xi90rd710jsiv0cz7wp89kz40vzrpn5chqh3m28";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ jre ];

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/java,share/applications}
    cp ${src} $out/share/java/
    makeWrapper ${jre}/bin/java $out/bin/raccoon \
      --add-flags "-jar $out/share/java/raccoon-${version}.jar"
    cp ${desktopItem}/share/applications/* $out/share/applications/
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Google Play Desktop client to download apps from Google Play without a phone";
    homepage = http://raccoon.onyxbits.de/;
    license = licenses.asl20;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
