{ stdenv
, withAria2 ? true, aria2 ? null
, withWget ? false, wget ? null
}:

assert withAria2 -> !withWget && aria2 != null;
assert withWget -> !withAria2 && wget != null;

let
  version = "1";
in

stdenv.mkDerivation rec {

  name = "rajce-download-${version}";

  src = ./rajce-download.sh;

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 ${src} $out/bin/rajce-download
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${src} file is not writable
    substituteInPlace $out/bin/rajce-download \
    ${stdenv.lib.optionalString (withAria2) "--subst-var-by aria2c '${aria2}/bin/aria2c'"} \
    ${stdenv.lib.optionalString (withWget) "--subst-var-by wget '${wget}/bin/wget'"}
  '';

  meta = with stdenv.lib; {
    description = "Download photos and videos in Rajce.net galleries";
    homepage = https://www.rajce.idnes.cz/;
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
