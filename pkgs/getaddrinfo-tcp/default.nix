{ stdenv
}:

let
  version = "1";
in

stdenv.mkDerivation rec {

  name = "getaddrinfo-tcp-${version}";

  src = ./getaddrinfo-tcp.c;

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    gcc -O2 -o getaddrinfo-tcp $src;
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D -m 555 -t $out/bin/ getaddrinfo-tcp
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Network address and service translation call with IPPROTO_TCP ai_protocol";
    homepage = https://en.wikipedia.org/wiki/Getaddrinfo;
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
