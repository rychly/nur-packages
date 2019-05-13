{ stdenv, buildLuaPackage, luaOlder, fetchgit, wrapLua
}:

let
  version = "2019.05.10";
in

buildLuaPackage {

  name = "convert-charsets-${version}";

  src = fetchgit {
    url = "https://gitlab.com/rychly/convert-charsets.git";
    rev = "2ce359e042be9bbdb2ad7c074354185f5d1267fd";
    sha256 = "1h7fsga2zdw7yvma3iyriy8spm9hagrqgmqlhcy8as3qkxmbhw4a";
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
