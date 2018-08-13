{ stdenv, fetchurl, unzip, makeWrapper, makeDesktopItem, patchelf
, libtool	# required by lib/libodbc.so.2
, jre
}:

let
  desktopItem = makeDesktopItem {
    name = "des-acide";
    exec = "des-acide";
    desktopName = "DES ACIDE ${version}";
    genericName = "DES ACIDE ${version}";
    comment = "ACIDE with Datalog Educational System (DES) built with SICStus Prolog";
    categories = "Development;";
  };
  plat = {
    "i686-linux" = "Linux32";
    "x86_64-linux" = "Linux64";
  }.${stdenv.system};
  sha256 = {
    "i686-linux" = "da146f1f872c028f1a64b7e8ec789a94dbe993da9216b5bf815ceb0b673bebca";
    "x86_64-linux" = "0470e6e23d1c5beab5d08d7539c752512c492ae2982c6ca4ebfd580124042b74";
  }.${stdenv.system};
  prolog = {
    "sicstus" = "SICStus";
    "swi" = "SWI";
  }.${versionProlog};
  versionParts = builtins.split "acide|(sicstus|swi)" version;
  versionMain = builtins.elemAt versionParts 0;
  versionAcide = builtins.elemAt versionParts 2;  # idx 2, not idx 1 which is an empty list for the separator
  versionProlog = builtins.head (builtins.elemAt versionParts 3);
  version = "6.1acide0.17sicstus";
in

stdenv.mkDerivation rec {

  name = "des-${version}";

  src = fetchurl {
    url = "mirror://sourceforge/des/DES${versionMain}ACIDE${versionAcide}${plat}${prolog}.zip";
    inherit sha256;
  };

  nativeBuildInputs = [ unzip makeWrapper patchelf ];
  buildInputs = [ jre libtool ];

  postUnpack = ''
    chmod 555 $sourceRoot/des_start $sourceRoot/lib/*.so.*	# must be executable
    rm $sourceRoot/des	# do not use wrapper (use patchelf instead of LD_LIBRARY_PATH)
    find $sourceRoot/resources -name Thumbs.db -delete
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,lib/des,share/applications,share/doc}
    mv ./doc $out/share/doc/des
    mv ./license $out/share/doc/des/
    mv ./lib/* $out/lib/ && rm -r ./lib	# so autoPatchelfHook should include those libraries
    mv ./* $out/lib/des/
    ln -s ../lib/des/des_start $out/bin/des
    ln -s des_start $out/lib/des/des	# required to run a console by ACIDE
    makeWrapper ${jre}/bin/java $out/bin/des-acide \
      --add-flags "-Djava.library.path=$out/lib -jar $out/lib/des/des_acide.jar" \
      --run "cd $out/lib/des"
    install -D -m 444 $out/lib/des/resources/images/icon.png $out/share/pixmaps/des-acide.png
    cp ${desktopItem}/share/applications/* $out/share/applications/
    runHook postInstall
  '';

  preFixup = ''
    # hack to avoid TMPDIR in RPATHs
    rm -rf "$(pwd)"
  '';

  postFixup = ''
    # patching ELF (does not work in preFixup due to "des: relocation error: des: symbol , version GLIBC_2.2.5 not defined in file libc.so.6 with link time reference")
    patchelf --set-rpath $(patchelf --print-rpath $out/lib/libodbc.so.2):${libtool.lib}/lib $out/lib/libodbc.so.2
    # for some reason (probably a build system bug), the binary isn't properly linked to $out/lib to find *.so files
    patchelf --set-rpath $(patchelf --print-rpath $out/lib/des/des_start):$out/lib --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/lib/des/des_start
  '';

  meta = with stdenv.lib; {
    description = "The Datalog Educational System (DES) is a deductive database system with Datalog, SQL, RA, TRC, and DRC as query languages";
    homepage = http://des.sourceforge.net/;
    license = [ licenses.lgpl3 licenses.gpl3 licenses.gpl2 ];
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
