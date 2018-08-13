{ stdenv, fetchurl, makeWrapper, makeDesktopItem
, jre
}:

let
  desktopItem = makeDesktopItem {
    name = "dummydroid";
    exec = "dummydroid";
    desktopName = "DummyDroid ${version}";
    genericName = "DummyDroid ${version}";
    comment = "Creates HW profiles for Android devices and uploads them into a Google Play";
    categories = "Network;Java";
  };
  version = "1.2";
in

stdenv.mkDerivation rec {

  name = "dummydroid-${version}";

  src = fetchurl {
    url = "http://www.onyxbits.de/sites/default/files/download/382/DummyDroid-${version}.jar";
    sha256 = "142n7m6vrpcyry9smgghckx1vxkvphnk65z5bpaj1s1n6hbirlps";
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
    makeWrapper ${jre}/bin/java $out/bin/dummydroid \
      --add-flags "-jar $out/share/java/DummyDroid-${version}.jar"
    cp ${desktopItem}/share/applications/* $out/share/applications/
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Creates HW profiles for Android devices and uploads them into a Google Play";
    homepage = http://www.onyxbits.de/dummydroid;
    license = licenses.asl20;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
