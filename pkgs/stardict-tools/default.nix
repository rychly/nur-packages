{stdenv, fetchurl, pkgconfig, gtk2, glib, zlib, intltool, pcre, libxml2
, withMysql ? false, mysql ? null
}:

assert withMysql -> mysql != null;

let
  versionParts = builtins.split "patch" version;
  versionMain = builtins.elemAt versionParts 0;
  versionPatch = builtins.elemAt versionParts 2;	# idx 2, not idx 1 which is an empty list for the separator
  version = "3.0.2patch6";
in

stdenv.mkDerivation rec {

  name= "stardict-tools-${version}";

  src = fetchurl {
    url = "https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/stardict-tools/${versionMain}-${versionPatch}/stardict-tools_${versionMain}.orig.tar.gz";
    sha256 = "17ybvb0lnh1gkh18kzc172pj566m6dpgj46zksayv28p4ynnyi8i";
  };

  buildInputs = [
    pkgconfig gtk2 glib zlib intltool pcre libxml2
  ] ++ stdenv.lib.optionals (withMysql) [
    mysql.lib
  ];

  patches = stdenv.lib.optionals (!withMysql) [
    ./nomysql.patch
  ];

  prePatch = let
    debian = fetchurl {
      url = "https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/stardict-tools/${versionMain}-${versionPatch}/stardict-tools_${versionMain}-${versionPatch}.debian.tar.xz";
      sha256 = "1c1h10b2x90nvppp510g8swiw4wk5by41argspjqy1620inzzh09";
    };
  in ''
    tar xJf "${debian}"
    patches="$patches $(cat debian/patches/series | sed 's|^|debian/patches/|')"
  '';

  # AM_CXXFLAGS needed for automake to fix "narrowing conversion of ‘255’ from ‘int’ to ‘char’" errors, see https://aur.archlinux.org/packages/stardict-tools/
  #preConfigure = ''
  #  export AM_CXXFLAGS="$CXXFLAGS -Wno-narrowing"
  #'';

  postPatch = ''
    # to install also tool binaries, not just an editor binary
    substituteInPlace src/Makefile.in \
      --replace "noinst_PROGRAMS =" "bin_PROGRAMS +="
  '' + stdenv.lib.optionalString (withMysql) ''
    # mysql hacks: we need dynamic linking as there is no libmysqlclient.a
    substituteInPlace tools/configure \
      --replace '/usr/local/include/mysql' '${mysql.lib}/include/mysql/' \
      --replace 'AC_FIND_FILE([libmysqlclient.a]' 'AC_FIND_FILE([libmysqlclient.so]' \
      --replace '/usr/local/lib/mysql' '${mysql.lib}/lib/mysql/' \
      --replace 'for y in libmysqlclient.a' 'for y in libmysqlclient.so' \
      --replace 'libmysqlclient.a' 'libmysqlclient.so'
  '';

  installPhase = ''
    runHook preInstall
    # editor and tools
    make install
    # rename tool binaries
    find $out/bin/ -not -name 'stardict[-_]*' -type f | sed 'p;s#bin/#bin/stardict_#' | xargs -n2 mv
    runHook postInstall
  '';

  postInstall = ''
    echo "Some tools may need some other additional packages installed to function, especially python scripts."
  '';

  meta = with stdenv.lib; {
    description = "Tools for an international dictionary supporting fuzzy and glob style matching";
    license = licenses.lgpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
