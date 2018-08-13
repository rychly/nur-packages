{ stdenv, makeDesktopItem
, exiv2, flickcurl, xdg-user-dirs
, withAria2 ? true, aria2 ? null
, withWget ? false, wget ? null
}:

assert withAria2 -> !withWget && aria2 != null;
assert withWget -> !withAria2 && wget != null;

let
  desktopItemCam2Pic = makeDesktopItem {
    name = "photos-from-camera-to-pictures";
    exec = "$out/bin/photos-from-camera-to-pictures";
    terminal = "true";
    desktopName = "Fotoaparát (z karty do počítače)";
    genericName = "Nahrání fotografií z karty do počítače";
    categories = "Graphics;Photography;";
  };
  desktopItemPic2Fli = makeDesktopItem {
    name = "photos-from-pictures-to-flickr";
    exec = "$out/bin/photos-from-pictures-to-flickr";
    terminal = "true";
    desktopName = "Fotoaparát (z počítače na internet)";
    genericName = "Nahrání fotografií z počítače na internet";
    categories = "Graphics;Photography;";
  };
  version = "1";
in

stdenv.mkDerivation rec {

  name = "photo-mgmt-${version}";

  srcs = [
    ./all-rename-exif.sh
    ./all-upload-flickr.sh
    ./flickr-download-set.sh
    ./flickr-perms-to-set.sh
    ./flickr-reorder-set.sh
    ./flickr-reorder-sets.sh
    ./photos-from-camera-to-pictures.sh
    ./photos-from-pictures-to-flickr.sh
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
    cp ${desktopItemCam2Pic}/share/applications/* ${desktopItemPic2Fli}/share/applications/* $out/share/applications/
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${srcs} files are not writable
    for I in $out/bin/*; do
      substituteInPlace $I \
        --subst-var-by out "$out" \
        ${stdenv.lib.optionalString (withAria2) "--subst-var-by aria2c '${aria2}/bin/aria2c'"} \
        ${stdenv.lib.optionalString (withWget) "--subst-var-by wget '${wget}/bin/wget'"} \
        --subst-var-by exiv2 "${exiv2}/bin/exiv2" \
        --subst-var-by flickcurl "${flickcurl}/bin/flickcurl" \
        --subst-var-by xdg-user-dir "${xdg-user-dirs}/bin/xdg-user-dir"
    done
  '';

  meta = with stdenv.lib; {
    description = "Photo management tools to download photos from a camera, put them into correct directories, and upload them to Flickr";
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
