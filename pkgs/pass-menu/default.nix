{ stdenv
, xdotool, rofi, pass
, withDunst ? true, dunst ? null
, withLibnotify ? false, libnotify ? null
}:

assert withDunst -> !withLibnotify && dunst != null;
assert withLibnotify -> !withDunst && libnotify != null;

let
  version = "1";
in

stdenv.mkDerivation rec {

  name = "pass-menu-${version}";

  src = ./pass-menu.sh;

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 ${src} $out/bin/pass-menu
    runHook postInstall
  '';

  postInstall = ''
    # patching must be done here, cannot do this in postPatch as ''${src} file is not writable
    substituteInPlace $out/bin/pass-menu \
      --subst-var-by pass "${pass}/bin/pass" \
      --subst-var-by rofi "${rofi}/bin/rofi" \
      --subst-var-by xdotool "${xdotool}/bin/xdotool"
  '' + stdenv.lib.optionalString (withDunst) ''
    substituteInPlace $out/bin/pass-menu \
      --subst-var-by notify-send "${dunst}/bin/dunstify"
  '' + stdenv.lib.optionalString (withLibnotify) ''
    substituteInPlace $out/bin/pass-menu \
      --subst-var-by notify-send "${libnotify}/bin/notify-send"
  '';

  meta = with stdenv.lib; {
    description = "A script to search pass for pass-name matching a given URL and its sub-paths, and, if found, enter its user-name and copy its password into a clipboard";
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
