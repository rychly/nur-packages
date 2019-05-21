{ stdenv, fetchurl
}:

let

  plat = {
    "i686-linux" = "linux-i686";
    "x86_64-linux" = "linux-x86_64";
  }.${stdenv.buildPlatform.system};
  sha256 = {
    "i686-linux" = "e9f2032d72df3d917323deb0e75b9678232544b0f13d42b5f18a8f89d149f64c";
    "x86_64-linux" = "aaedeb439b0834c7b83a43a03da52ae1532daff1e706772dcf98d9e5b755c43d";
  }.${stdenv.buildPlatform.system};
  versionParts = builtins.splitVersion version;
  versionMajor = builtins.elemAt versionParts 0 + "." + builtins.elemAt versionParts 1 + "." + builtins.elemAt versionParts 2;
  versionMinor = builtins.elemAt versionParts 3;
  versionDate = builtins.elemAt versionParts 5 + "-" + builtins.elemAt versionParts 6 + "-" + builtins.elemAt versionParts 7 + "-"
    + builtins.elemAt versionParts 8 + "-" + builtins.elemAt versionParts 9 + "-" + builtins.elemAt versionParts 10;
  versionDir = builtins.elemAt versionParts 5 + "/" + builtins.elemAt versionParts 6;
  version = "1.9.2.29pre2012.05.03.03.32.04";


  xulrunner192 = stdenv.mkDerivation rec {

    name = "xulrunner-${version}";

    src = fetchurl {
      url = "https://ftp.mozilla.org/pub/xulrunner/nightly/${versionDir}/${versionDate}-mozilla-${versionMajor}/xulrunner-${versionMajor}.${versionMinor}pre.en-US.${plat}.tar.bz2";
      inherit sha256;
    };

    postPatch = ''
      sed -i "s|^\\(moz_libdir=\\).*\$|\\1$out/lib|" ./xulrunner
    '';

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      mv ./* $out/lib/
      runHook postInstall
    '';

    setupHook = builtins.toFile "setupHook.sh" ''
      if [ -z "$MOZILLA_FIVE_HOME" ]; then export MOZILLA_FIVE_HOME="$1/lib"; fi
    '';

    meta = with stdenv.lib; {
      description = "Mozilla XULRunner application framework";
      homepage = "https://developer.mozilla.org/en-US/docs/Archive/Mozilla/XULRunner/${versionMajor}";
      license = with licenses; [ mpl11 gpl2 lgpl21 ];
      #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
      platforms = platforms.linux;
    };

    passthru = {
      home = "${xulrunner192}/lib";
    };

  };


in xulrunner192
