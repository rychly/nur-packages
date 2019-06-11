{ stdenv, buildLuaPackage, luaOlder, fetchgit, wrapLua
}:

let
  version = "2019.06.10";
in

buildLuaPackage {

  name = "convert-charsets-${version}";

  src = fetchgit {
    url = "https://gitlab.com/rychly/convert-charsets.git";
    rev = "7cb53c58dbbd7bd99887d99cbd1d2d37";
    sha256 = "047py4a0v6r07yi81xnraqrs4rpkbd1di0chgamnm88nqsnxwqjj";
  };

  disabled = ( luaOlder "5.1" );
  buildInputs = [ wrapLua ];

  postFixup = ''
    wrapLuaPrograms
  '';

  meta = with stdenv.lib; {
    description = "Lua scripts to convert strings between UTF-8 and other charsets and from UTF-8 to ASCII and SGML";
    homepage = https://gitlab.com/rychly/convert-charsets;
    license = licenses.gpl2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
