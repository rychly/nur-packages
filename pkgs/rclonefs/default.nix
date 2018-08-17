{ stdenv
, rclone
}:

let
  version = "1";
in

stdenv.mkDerivation rec {

  name = "rclonefs-${version}";

  src = ./rclonefs.sh;

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 ${src} $out/bin/rclonefs
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${src} file is not writable
    substituteInPlace $out/bin/rclonefs \
      --subst-var-by rclone "${rclone}/bin/rclone"
  '';

  meta = with stdenv.lib; {
    description = "A script to mount rclone targets by mount command in /etc/fstab or systemd-mount";
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
