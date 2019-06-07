{ stdenv, buildLuaPackage, luaOlder, fetchgit, wrapLua
, luafilesystem, luasocket, convert-charsets
}:

let
  version = "2019.06.07";
in

buildLuaPackage {

  name = "mail-parser-${version}";

  src = fetchgit {
    url = "https://gitlab.com/rychly/mail-parser.git";
    rev = "a239dfc1337341a9eb3d173f136d06d4";
    sha256 = "13v4psa9bq36fjpvpfvh2vkjr3r68sd6fppp6y4nlaj552qzrd1z";
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
