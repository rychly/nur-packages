{ stdenv, fetchFromGitHub, makeWrapper, makeDesktopItem
, python2Packages, libusb1, pkexecPath ? "/run/wrappers/bin/pkexec"
}:

let
  desktopItem = makeDesktopItem {
    name = "rkflashkit";
    exec = "rkflashkit-pkexec";
    icon = "rkflashkit";
    desktopName = "rkflashkit ${version}";
    genericName = "rkflashkit ${version}";
    comment = "An open source toolkit for flashing Linux kernel images to rockchip rk3066/rk3188/rk3288 etc. based devices";
    categories = "System;";
  };
  inherit (python2Packages) python;
  version = "2017.11.10";
in

python2Packages.buildPythonApplication rec {

  name = "rkflashkit-${version}";

  src = fetchFromGitHub {
    owner = "linuxerwang";
    repo = "rkflashkit";
    rev = "e43cb3dd63536f2147c0bc94ab39ff7147ecd40b";
    sha256 = "1zh70n6kijhqbmqv58n5p42950w1vw63xr5j6shz67b7ggl3m9i0";
  };

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = with python2Packages; [ pygtk ];

  postPatch = ''
    substituteInPlace wscript \
      --replace "debian/usr/share/rkflashkit/lib" "$out/${python.sitePackages}"
    substituteInPlace run.py \
      --replace "sys.path.append(RKFLASHKIT_PATH)" ""
  '';

  doCheck = false;	# there are no tests (missing nix_run_setup executed by python)

  configurePhase = ''
    runHook preConfigure
    python waf configure --prefix=$out	# even if the prefix does not work here, use it just in case of future versions
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    python waf
    runHook postBuild
  '';

  installPhase = let
    pythonSiteDir = "${python.sitePackages}/rkflashkit";
  in ''
    runHook preInstall
    python waf install
    mv run.py $out/${pythonSiteDir}/
    makeWrapper ${python.interpreter} $out/bin/rkflashkit \
      --prefix LD_LIBRARY_PATH : ${stdenv.lib.makeLibraryPath [ libusb1 ]} \
      --set PYTHONPATH "$PYTHONPATH:$(toPythonPath $out)" \
      --add-flags $out/${pythonSiteDir}/run.py
    # polkit (cannot use makeWrapper on ${pkexecPath} as the target is not file but symlink which results into "Builder called die: Cannot wrap '...' because it is not an executable file"
    cat >$out/bin/rkflashkit-pkexec <<END
    #!/bin/sh
    exec ${pkexecPath} $out/bin/rkflashkit \$@
    END
    chmod 555 $out/bin/rkflashkit-pkexec
    mkdir -p $out/share/polkit-1/actions
    substitute debian/usr/share/polkit-1/actions/com.ubuntu.pkexec.rkflashkit.policy $out/share/polkit-1/actions/com.ubuntu.pkexec.rkflashkit.policy \
      --replace "/usr/bin/" "$out/bin/"
    # desktop and icons
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/
    install -D -m 444 ./debian/usr/share/rkflashkit/images/rkflashkit.png $out/share/pixmaps/rkflashkit.png
    install -D -m 444 ./debian/usr/share/rkflashkit/images/rkflashkit.svg $out/share/icons/hicolor/scalable/apps/rkflashkit.svg
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "An open source toolkit for flashing Linux kernel images to rockchip rk3066/rk3188/rk3288 etc. based devices";
    homepage = https://github.com/linuxerwang/rkflashkit;
    license = licenses.gpl2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
