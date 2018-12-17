{ stdenv
, bluez
}:

let
  version = "1";
in

stdenv.mkDerivation rec {

  name = "bluez-alsa-tools-${version}";

  srcs = [
    ./bluealsa-amixer.sh
    ./bluealsa-asound.sh
    ./bluealsa-control.sh
    ./bluetooth-disconnect.sh
    ./bluetooth-reconnect.sh
  ];

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    for I in ${builtins.concatStringsSep " " srcs}; do
      _name=$(basename $I .sh)
      install -D -m 555 $I $out/bin/''${_name#*-}	# strip nix-store hash from the source filename
    done
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${src} file is not writable
    substituteInPlace $out/bin/bluetooth-reconnect \
      --subst-var-by bluetoothctl "${bluez}/bin/bluetoothctl"
    substituteInPlace $out/bin/bluetooth-disconnect \
      --subst-var-by bluetoothctl "${bluez}/bin/bluetoothctl"
    substituteInPlace $out/bin/bluealsa-control \
      --subst-var-by out "$out"
  '';

  meta = with stdenv.lib; {
    description = "Scripts to (re)connect a given bluetooth device and set bluez-alsa";
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
