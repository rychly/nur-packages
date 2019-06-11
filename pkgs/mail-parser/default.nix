{ stdenv, buildLuaPackage, luaOlder, fetchgit, wrapLua
, luafilesystem, luasocket, convert-charsets
}:

let
  version = "2019.06.10";
in

buildLuaPackage {

  name = "mail-parser-${version}";

  src = fetchgit {
    url = "https://gitlab.com/rychly/mail-parser.git";
    rev = "0b4a2c4a7a889a6e8048480ecaee630b";
    sha256 = "02y0r3hd9q341rs1a3lvmfxl8di3r7fwl2gpsv9i5xs5vw9qln1j";
  };

  disabled = ( luaOlder "5.1" );
  buildInputs = [ wrapLua ];
  propagatedBuildInputs = [ luafilesystem luasocket convert-charsets ];

  postFixup = ''
    wrapLuaPrograms
  '';

  meta = with stdenv.lib; {
    description = "Lua scripts to parse mail including its MIME structures.";
    homepage = https://gitlab.com/rychly/mail-parser;
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
