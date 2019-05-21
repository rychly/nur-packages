{ stdenv, requireFile, dpkg, makeWrapper, makeDesktopItem
, glib, gtk2, libXtst	# required by libswt-pi-gtk-*.so extracted and linked by eclipse runtime
, libXt, alsaLib	# required by libxpcom
, jre
# GTK+2 for org.eclipse.swt.SWTError: No more handles [Unknown Mozilla path (MOZILLA_FIVE_HOME not set)]
# and set env variable SWT_GTK3=0 in ${MODELIO_PATH}/modelio.sh to use GTK+2 instead of GTK+3
# for org.eclipse.e4.core.di.InjectionException: org.eclipse.swt.SWTError: No more handles [Browser style SWT.MOZILLA and Java system property org.eclipse.swt.browser.DefaultType=mozilla are not supported with GTK 3 as XULRunner is not ported for GTK 3 yet] org.eclipse.swt.SWTError: No more handles [Browser style SWT.MOZILLA and Java system property org.eclipse.swt.browser.DefaultType=mozilla are not supported with GTK 3 as XULRunner is not ported for GTK 3 yet]
# FIXED: 1.9.2.x XULRunner releases provide require API (not available in later versions of XULRunner)
, xulrunner192
# wrapping for plugins
, plugins, symlinkJoin
, version, fileNamePrefixWithoutPlat, sha256x86, sha256x64
}:

let

  desktopItem = makeDesktopItem {
    name = "modelio";
    exec = "modelio";
    icon = "modelio";
    desktopName = "Modelio ${versionMain}";
    genericName = "Modelio ${versionMain}";
    comment = "An Integrated Model-Driven Development Environment (MDA)";
    categories = "Development;";
  };
  plat = {
    "i686-linux" = "i386";
    "x86_64-linux" = "amd64";
  }.${stdenv.buildPlatform.system};
  platBits = {
    "i686-linux" = "32";
    "x86_64-linux" = "64";
  }.${stdenv.buildPlatform.system};
  sha256 = {
    "i686-linux" = sha256x86;
    "x86_64-linux" = sha256x64;
  }.${stdenv.buildPlatform.system};
  versionParts = builtins.split "build" version;
  versionMain = builtins.elemAt versionParts 0;
  versionMainParts = builtins.splitVersion versionMain;
  versionMajor = builtins.elemAt versionMainParts 0 + "." + builtins.elemAt versionMainParts 1;
  versionMajorDash = builtins.elemAt versionMainParts 0 + "-" + builtins.elemAt versionMainParts 1;
  versionBuild = builtins.elemAt versionParts 2;	# idx 2, not idx 1 which is an empty list for the separator


  unwrapped = stdenv.mkDerivation rec {

    name = "modelio-${version}";

    # for referring in the wrapper outside of the derivation
    inherit version;
    inherit versionMajor;

    src = requireFile rec {
      name = "${fileNamePrefixWithoutPlat}${plat}.deb";
      url = "https://www.modeliosoft.com/en/downloads/modeliosoft-products/modelio-${versionMajorDash}-x.html";
      inherit sha256;
      message = ''
        This Nix expression requires that ${name} already be part of the store. To
        obtain it you need to

        - navigate to ${url}
        - download "Modelio core ${versionMain} - Debian ${platBits}-bit"
        - sign in or create an Modelio account if neccessary

        and then add the file to the Nix store using either:
          nix-store --add-fixed sha256 ${name}
        or
          nix-prefetch-url --type sha256 file:///path/to/${name}
      '';
    };

    nativeBuildInputs = [ dpkg makeWrapper ];
    buildInputs = [ jre xulrunner192 ];

    unpackCmd = "mkdir root && dpkg-deb -x $curSrc root";

    postUnpack = ''
      # use our own wrapper
      rm $sourceRoot/usr/lib/modelio-by-modeliosoft${versionMajor}/modelio.sh
      # remove bundled Java
      rm -rf $sourceRoot/usr/lib/modelio-by-modeliosoft${versionMajor}/{jre,lib}
    '';

    dontConfigure = true;
    dontBuild = true;

    # patchShebangs will be done automatically (e.g., in the default postInstall phase)

    installPhase = ''
      runHook preInstall
      mkdir -p $out/{bin,etc,lib}
      mv ./usr/lib/modelio-by-modeliosoft${versionMajor} $out/lib/
      mv ./etc/modelio-by-modeliosoft${versionMajor} $out/etc/
      # wrappers
      makeWrapper $out/lib/modelio-by-modeliosoft${versionMajor}/modelio $out/bin/modelio \
        --prefix PATH : ${stdenv.lib.makeBinPath [ jre ]} \
        --prefix LD_LIBRARY_PATH : ${stdenv.lib.makeLibraryPath [ glib gtk2 libXtst libXt alsaLib xulrunner192 ]} \
        --set JAVA_HOME ${jre.home} \
        --set MOZILLA_FIVE_HOME ${xulrunner192.home} \
        --set SWT_GTK3 0 \
        --set UBUNTU_MENUPROXY 0 \
        --set LIBOVERLAY_SCROLLBAR 0 \
        --set GDK_NATIVE_WINDOWS 1 \
        --set GTK2_RC_FILES $out/lib/modelio-by-modeliosoft${versionMajor}/gtkrc-modelio
      # icons
      install -D -m 444 $out/lib/modelio-by-modeliosoft${versionMajor}/icon.xpm $out/share/pixmaps/modelio.xpm
      install -D -m 444 ./usr/share/icons/hicolor/scalable/apps/modelio_logo_${versionMajor}.svg $out/share/icons/hicolor/scalable/apps/modelio.svg
      mkdir -p $out/share/applications
      cp ${desktopItem}/share/applications/* $out/share/applications/
      runHook postInstall
    '';

    preFixup = ''
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/lib/modelio-by-modeliosoft${versionMajor}/modelio
    '';

    meta = with stdenv.lib; {
      description = "A modeling environment supporting a wide range of UML/BPMN models and diagrams";
      homepage = https://www.modeliosoft.com/en/modules/modelio-modeler.html;
      license = licenses.unfree;
      #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
      platforms = platforms.unix;
    };

    passthru = {
      inherit src;	# to prevent removal of the src from nix-store
    };
  };


in if plugins == [] then unwrapped
  else import ./wrapper.nix {
    inherit symlinkJoin plugins;
    modelio = unwrapped;
  }
