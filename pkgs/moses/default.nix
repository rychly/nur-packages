{ stdenv, buildLuarocksPackage, luaOlder, luaAtLeast, fetchurl
}:

let
  version = "2.1.0-1";
in

buildLuarocksPackage {

  inherit version;

  pname = "moses";

  src = fetchurl {
    url = "https://luarocks.org/manifests/yonaba/moses-${version}.src.rock";
    sha256 = "14lmxx4i8ycj45r3x6rjnvdanjc3rxn2cxn66ykm68psvi0677w3";
  };

  disabled = ( luaOlder "5.1" ) || ( luaAtLeast "5.4" );
  buildType = "builtin";

  meta = with stdenv.lib; {
    description = "Utility-belt library for functional programming in Lua";
    homepage = http://yonaba.github.com/Moses/;
    license = licenses.mit;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
