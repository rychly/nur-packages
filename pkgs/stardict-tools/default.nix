{stdenv, fetchurl, pkgconfig, gtk2, glib, zlib, intltool, pcre
, withMysql ? false, mysql ? null
}:

assert withMysql -> mysql != null;

let
  version = "3.0.1";
in

stdenv.mkDerivation rec {

  name= "stardict-tools-${version}";

  src = fetchurl {
    url = "mirror://sourceforge/stardict-4/${version}/stardict-tools-${version}.tar.bz2";
    sha256 = "9aa89b78ae09d68ff0218c76c8de0763225718a5b372aa8274c33e9a3fd60a20";
  };

  buildInputs = [
    pkgconfig gtk2 glib zlib intltool pcre
  ] ++ stdenv.lib.optionals (withMysql) [
    mysql.lib
  ];

  patches = [
    # a list of p0 patches from gentoo devs
    ./overflow.patch
    ./gcc43.patch
  ] ++ stdenv.lib.optionals (!withMysql) [
    ./nomysql.patch
  ];

  # AM_CXXFLAGS needed for automake to fix "narrowing conversion of ‘255’ from ‘int’ to ‘char’" errors, see https://aur.archlinux.org/packages/stardict-tools/
  preConfigure = ''
    export AM_CXXFLAGS="$CXXFLAGS -Wno-narrowing"
  '';

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
