{ stdenv_32bit, fetchurl, unzip
}:

let
  version = "1.0.6";
in

stdenv_32bit.mkDerivation rec {

  name = "imgrepackerrk-${version}";

  src = fetchurl {
    name = "${name}.zip";
    url = "https://forum.xda-developers.com/attachment.php?s=24396926521f5452838e662bb9db3161&attachmentid=4136650&d=1493819013";
    sha256 = "7d90934e0c976c2ad2d154944f987b85b5c8f689593cfb701db017cbe2e3619f";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 -t $out/bin/ imgrepackerrk
    runHook postInstall
  '';

  preFixup = ''
    patchelf --set-interpreter ${stdenv_32bit.cc.libc.out}/lib/ld-linux.so.2 $out/bin/imgrepackerrk
    patchelf --set-rpath ${stdenv_32bit.cc.cc.lib}/lib $out/bin/imgrepackerrk
  '';

  meta = with stdenv_32bit.lib; {
    description = "A closed-source RockChip's firmware images (*.img) unpacker/packer";
    homepage = "https://forum.xda-developers.com/showthread.php?t=2257331";
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
