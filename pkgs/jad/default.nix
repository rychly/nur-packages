{ stdenv_32bit, fetchurl, unzip
}:

let
  version = "1.5.8e";
in

stdenv_32bit.mkDerivation rec {

  name = "jad-${version}";

  src = fetchurl {
    url = "https://web.archive.org/web/20080214075546/http://www.kpdus.com/jad/linux/jadls${builtins.replaceStrings ["." "e"] ["" ""] version}.zip";
    sha256 = "2878e19fc1fdd725b516f538a57b02aaec1b2d1e4b106d550230381ffa9c0c81";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 -t $out/bin/ jad
    runHook postInstall
  '';

  meta = with stdenv_32bit.lib; {
    description = "The JAD is a fast JAva Decompiler";
    homepage = https://web.archive.org/web/20080214075546/http://www.kpdus.com/jad.html;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
