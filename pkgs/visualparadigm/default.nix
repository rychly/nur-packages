{ stdenv, fetchurl, makeWrapper, makeDesktopItem
, jre, which
}:

let
  desktopItemVP = makeDesktopItem {
    name = "visualparadigm";
    exec = "visualparadigm";
    icon = "visualparadigm";
    desktopName = "Visual Paradigm ${versionMain}";
    genericName = "Visual Paradigm ${versionMain}";
    comment = "Software Design Tool";
    categories = "Development;";
  };
  desktopItemShape = makeDesktopItem {
    name = "visualparadigm-shapeeditor";
    exec = "visualparadigm-shapeeditor";
    icon = "visualparadigm";
    desktopName = "Visual Paradigm Shape Editor ${versionMain}";
    genericName = "Visual Paradigm Shape Editor ${versionMain}";
    comment = "Software Design Tool";
    categories = "Development;";
  };
  versionParts = builtins.split "build" version;
  versionMain = builtins.elemAt versionParts 0;
  versionBuild = builtins.elemAt versionParts 2;	# idx 2, not idx 1 which is an empty list for the separator
  version = "15.1build20180932";
in

stdenv.mkDerivation rec {

  name = "visualparadigm-${version}";

  src = fetchurl {
    url = "https://eu6.visual-paradigm.com/visual-paradigm/vp${versionMain}/${versionBuild}/Visual_Paradigm_${builtins.replaceStrings [ "." ] [ "_" ] versionMain}_${versionBuild}_Linux64_InstallFree.tar.gz";
    sha256 = "0iv63zj3hfgml1irmamfizsjkyc9xl95xls5v8m4xbby35kp2isn";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ jre ];

  unpackPhase = ''
    runHook preUnpack
    tar xfz ${src} "Visual_Paradigm_${versionMain}/Application" "Visual_Paradigm_${versionMain}/.install4j"
    runHook postUnpack
  '';

  postUnpack = ''
    # remove uninstaller, updater, and Windows binaries (bundled Java was not extracted)
    rm -rf ./Visual_Paradigm_${versionMain}/Application/{uninstaller,updatesynchronizer,bin/vp_windows,ormlib/dotnet}
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = let
    wrapperParams = ''
      --prefix PATH : ${stdenv.lib.makeBinPath [ jre which ]} \
      --set JAVA_HOME ${jre.home} \
      --set INSTALL4J_JAVA_HOME_OVERRIDE ${jre.home} \
      --set INSTALL4J_NO_DB 1
    '';
  in ''
    runHook preInstall
    mkdir -p $out/{bin,lib}
    mv ./Visual_Paradigm_${versionMain} $out/lib/visualparadigm
    # wrappers
    makeWrapper $out/lib/visualparadigm/Application/bin/Visual_Paradigm $out/bin/visualparadigm \
      ${wrapperParams}
    makeWrapper $out/lib/visualparadigm/Application/bin/Visual_Paradigm_Shape_Editor $out/bin/visualparadigm-shapeeditor \
      ${wrapperParams}
    # icons
    install -D -m 444 $out/lib/visualparadigm/Application/resources/vpuml.png $out/share/pixmaps/visualparadigm.png
    mkdir -p $out/share/applications
    cp ${desktopItemVP}/share/applications/* ${desktopItemShape}/share/applications/* $out/share/applications/
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "A software design tool supporting UML, SysML, ERD, DFD, BPMN, ArchiMate, etc.";
    homepage = https://visual-paradigm.com/;
    license = licenses.unfree;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
