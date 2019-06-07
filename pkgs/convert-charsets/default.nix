{ stdenv, buildLuaPackage, luaOlder, fetchgit, wrapLua
}:

let
  version = "2019.06.07";
in

buildLuaPackage {

  name = "convert-charsets-${version}";

  src = fetchgit {
    url = "https://gitlab.com/rychly/convert-charsets.git";
    rev = "ef792934516c1928909e58d060e16a83";
    sha256 = "0n0z6hdrw6w2q6a5zginsb82yhzym84b5wd78cjvyfjkl3vi4wkz";
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
