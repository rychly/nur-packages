{ stdenv, buildLuarocksPackage, luaOlder, luaAtLeast, fetchurl
, luaexpat, luasocket
}:

let
  version = "1.2.2-1";
in

buildLuarocksPackage {

  inherit version;

  pname = "luaxmlrpc";

  src = fetchurl {
    url = "https://luarocks.org/manifests/rumkex/luaxmlrpc-${version}.src.rock";
    sha256 = "1ahm65328qh5v918amb9dkjxhz9g2n0dgc1w1higxh5dm5dq09qz";
  };

  disabled = ( luaOlder "5.1" ) || ( luaAtLeast "5.3" );
  propagatedBuildInputs = [ luaexpat luasocket ];
  buildType = "builtin";

  meta = with stdenv.lib; {
    description = "Allows to access and provide XML-RPC services";
    homepage = http://keplerproject.github.io/lua-xmlrpc;
    license = licenses.gpl2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
