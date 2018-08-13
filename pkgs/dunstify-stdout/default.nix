{ stdenv
, dunst
}:

let
  version = "1";
in

stdenv.mkDerivation rec {

  name = "dunstify-stdout-${version}";

  src = ./dunstify-stdout.sh;

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 ${src} $out/bin/dunstify-stdout
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${src} file is not writable
    substituteInPlace $out/bin/dunstify-stdout \
      --subst-var-by dunstify "${dunst}/bin/dunstify"
  '';

  meta = with stdenv.lib; {
    description = "A script to send a synchronous message and stdout to dunst with an icon and a timeout";
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
