{ stdenv
, virtualbox, dunstify-stdout
}:

let
  version = "1";
in

stdenv.mkDerivation rec {

  name = "rofi-modi-vbox-${version}";

  src = ./rofi-modi-vbox.sh;

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 ${src} $out/bin/rofi-modi-vbox
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${src} file is not writable
    substituteInPlace $out/bin/rofi-modi-vbox \
      --subst-var-by VBoxManage "${virtualbox}/bin/VBoxManage" \
      --subst-var-by dunstify-stdout "${dunstify-stdout}/bin/dunstify-stdout"
  '';

  meta = with stdenv.lib; {
    description = "A script to list VirtualBox machines and their states or toggle a given state of a given virtual machine";
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
