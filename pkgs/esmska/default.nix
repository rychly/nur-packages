{ stdenv, fetchFromGitHub, ant, jdk, makeWrapper, makeDesktopItem
, jre
}:

let
  desktopItem = makeDesktopItem {
    name = "esmska";
    exec = "esmska";
    icon = "esmska";
    desktopName = "Esmska ${version}";
    genericName = "Esmska ${version}";
    comment = "Program for Sending SMS over the Internet";
    categories = "Network;InstantMessaging";
  };
  version = "1.9.2";
in

stdenv.mkDerivation rec {

  name = "esmska-${version}";

  src = fetchFromGitHub {
    owner = "kparal";
    repo = "esmska";
    rev = "v${version}";
    sha256 = "1lwc3imy885v1ijpvxsfrxkc98dj7kasmbgc26rg7idwdxvfav14";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ ant jdk ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    ant
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/java,lib/esmska}
    # JAR files that are intended to be used by other packages
    mv ./dist/esmska.jar ./dist/lib $out/share/java/
    # other resources
    mv ./dist/{gateways,icons} ./dist/*.conf $out/lib/esmska/
    # wrappers
    # Disable IPv6 because it breaks Java networking on Ubuntu and Debian
    # http://code.google.com/p/esmska/issues/detail?id=252 http://code.google.com/p/esmska/issues/detail?id=233
    makeWrapper ${jre}/bin/java $out/bin/esmska \
      --add-flags "-Djava.net.preferIPv4Stack=true -jar $out/share/java/esmska.jar" \
      --run "cd $out/lib/esmska"
    # icons
    install -D -m 444 $out/lib/esmska/icons/esmska.png $out/share/pixmaps/esmska.png
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "A program for sending SMS over the Internet.";
    homepage = https://github.com/kparal/esmska;
    license = licenses.agpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
