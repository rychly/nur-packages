{ stdenv, buildLuarocksPackage, luaOlder, fetchurl
, oracle-instantclient, zlib
}:

let
  version = "2.4.0-1";
in

buildLuarocksPackage {

  inherit version;

  pname = "luasql-oci8";

  src = fetchurl {
    url = "https://luarocks.org/luasql-oci8-${version}.src.rock";
    sha256 = "0rx9b2gq1ng3scppvp1i2n5bj0ym65lnfynl7rnz2ds5a3yby4k1";
  };

  disabled = ( luaOlder "5.1" );
  buildInputs = [ oracle-instantclient zlib ];
  buildType = "builtin";

  rockspecFilename = "../luasql-oci8-${version}.rockspec";

  meta = with stdenv.lib; {
    description = "Database connectivity for Lua (Oracle driver)";
    homepage = http://www.keplerproject.org/luasql/;
    license = licenses.mit;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
