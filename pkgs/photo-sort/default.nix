{ stdenv, makeDesktopItem
, exiv2, xdg-user-dirs
}:

let
  desktopItemCam2Pic = makeDesktopItem {
    name = "photos-from-camera-to-pictures";
    exec = "$out/bin/photos-from-camera-to-pictures";
    terminal = "true";
    desktopName = "Fotoaparát (z karty do počítače)";
    genericName = "Nahrání fotografií z karty do počítače";
    categories = "Graphics;Photography;";
  };
  version = "1";
in

stdenv.mkDerivation rec {

  name = "photo-sort-${version}";

  srcs = [
    ./all-rename-exif.sh
    ./photos-from-camera-to-pictures.sh
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
    mkdir -p $out/share/applications
    cp ${desktopItemCam2Pic}/share/applications/* $out/share/applications/
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${srcs} files are not writable
    for I in $out/bin/*; do
      substituteInPlace $I \
        --subst-var-by out "$out" \
        --subst-var-by exiv2 "${exiv2}/bin/exiv2" \
        --subst-var-by xdg-user-dir "${xdg-user-dirs}/bin/xdg-user-dir"
    done
  '';

  meta = with stdenv.lib; {
    description = "Photo management tools to download photos from a camera and sort them into correct directories";
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
