{ stdenv, fetchurl, makeWrapper
, wine
}:

let
  version = "3.15";
in

stdenv.mkDerivation rec {

  name = "winbox-${version}";

  src = fetchurl {
    url = "https://download.mikrotik.com/routeros/winbox/${version}/winbox.exe";
    sha256 = "87b0756aa411244f4b172eef8983bef723202bf7f34d641892826503cadec560";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ wine ];

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -D -m 555 ${src} $out/libexec/winbox/winbox.exe
    makeWrapper ${wine}/bin/wine $out/bin/winbox \
      --add-flags "$out/libexec/winbox/winbox.exe"
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Configuration tool for RouterOS";
    homepage = "https://wiki.mikrotik.com/wiki/Manual:Winbox";
    license = licenses.unfree;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
