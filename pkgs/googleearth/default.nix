# adopted from https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/applications/misc/googleearth/default.nix
# sha256 is often varying even for the same version number and it is impossible to override it in the original package (defined in the "let" statement), so we will update it locally

{ stdenv, fetchurl, glibc, libGLU_combined, freetype, glib, libSM, libICE, libXi, libXv
, libXrender, libXrandr, libXfixes, libXcursor, libXinerama, libXext, libX11, qt4
, zlib, fontconfig, dpkg, libproxy, libxml2, gstreamer, gst_all_1, dbus }:

let
  fullPath = stdenv.lib.makeLibraryPath [
    glibc
    glib
    stdenv.cc.cc
    libSM
    libICE
    libXi
    libXv
    libGLU_combined
    libXrender
    libXrandr
    libXfixes
    libXcursor
    libXinerama
    freetype
    libXext
    libX11
    zlib
    fontconfig
    libproxy
    libxml2
    gstreamer
    dbus
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
  ];
  plat = {
    "i686-linux" = "i386";
    "x86_64-linux" = "amd64";
  }.${stdenv.system};
  sha256 = {
    "i686-linux" = "16y3sv6cbg71r55kqdqj30szhgnsgk17jpf6j2w7qixl3n233z1b";
    "x86_64-linux" = "0dwnppn5snl5bwkdrgj4cyylnhngi0g66fn2k41j3dvis83x24k6";
  }.${stdenv.system};
  version = "7.1.8.3036";
in

stdenv.mkDerivation rec {

  name = "googleearth-${version}";

  src = fetchurl {
    url = "https://dl.google.com/linux/earth/deb/pool/main/g/google-earth-stable/google-earth-stable_${version}-r0_${plat}.deb";
    inherit sha256;
  };

  phases = [ "unpackPhase" "installPhase" "checkPhase" ];

  doCheck = true;

  buildInputs = [ dpkg ];

  unpackCmd = "mkdir root && dpkg-deb -x $curSrc root";

  installPhase =''
    runHook preInstall

    mkdir $out
    mv usr/* $out/
    rmdir usr
    mv * $out/
    rm $out/bin/google-earth $out/opt/google/earth/free/googleearth

    # patch and link googleearth binary
    ln -s $out/opt/google/earth/free/googleearth-bin $out/bin/googleearth
    patchelf --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${fullPath}:\$ORIGIN" \
      $out/opt/google/earth/free/googleearth-bin

    # patch and link gpsbabel binary
    ln -s $out/opt/google/earth/free/gpsbabel $out/bin/gpsbabel
    patchelf --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${fullPath}:\$ORIGIN" \
      $out/opt/google/earth/free/gpsbabel

    # patch libraries
    for a in $out/opt/google/earth/free/*.so* ; do
      patchelf --set-rpath "${fullPath}:\$ORIGIN" $a
    done

    runHook postInstall
  '';

  checkPhase = ''
    runHook preCheck
    $out/bin/gpsbabel -V > /dev/null
    runHook postCheck
  '';

  dontPatchELF = true;

  meta = with stdenv.lib; {
    description = "A world sphere viewer";
    homepage = http://earth.google.com;
    license = licenses.unfree;
    maintainers = with maintainers; [ markus1189 ];
    platforms = platforms.linux;
  };
}
