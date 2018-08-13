{ stdenv, makeWrapper
, python2Packages
}:

let
  inherit (python2Packages) python;
  version = "1";
in

python2Packages.buildPythonApplication rec {

  name = "rofi-modi-mount-${version}";

  src = ./rofi-modi-mount.py;

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  propagatedBuildInputs = with python2Packages; [ dbus-python pygobject3 ];

  dontConfigure = true;
  dontBuild = true;
  doCheck = false;	# there are no tests (missing nix_run_setup executed by python)

  installPhase = let
    pythonSiteDir = "${python.sitePackages}";
  in ''
    runHook preInstall
    mkdir -p $out/${pythonSiteDir}
    cp ${src} $out/${pythonSiteDir}/rofi-modi-mount.py
    makeWrapper ${python.interpreter} $out/bin/rofi-modi-mount \
      --set PYTHONPATH "$PYTHONPATH:$(toPythonPath $out)" \
      --add-flags $out/${pythonSiteDir}/rofi-modi-mount.py
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "A script to list mountable devices and to mount, unmount, or eject them";
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
