{ stdenv
, glib, gnugrep
}:

let
  version = "1";
in

stdenv.mkDerivation rec {

  name = "gio-mounter-${version}";

  src = ./mount-gio.sh;

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 ${src} $out/bin/mount-gio
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${src} file is not writable
    substituteInPlace $out/bin/mount-gio \
      --subst-var-by grep "${gnugrep}/bin/grep" \
      --subst-var-by gio "${glib}/bin/gio"
  '';

  meta = with stdenv.lib; {
    description = "A script to mount predefined storages via GIO";
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
