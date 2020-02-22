{ stdenv, buildLuarocksPackage, luaOlder, fetchurl
}:

let
  version = "0.5-1";
in

buildLuarocksPackage {

  inherit version;

  pname = "gumbo";

  src = fetchurl {
    url = "https://luarocks.org/manifests/craigb/gumbo-${version}.src.rock";
    sha256 = "0p36d63bjckn36yv9jly08igqjkx7xicq4q479f69njiaxlhag6f";
  };

  disabled = ( luaOlder "5.1" );
  buildType = "builtin";

  meta = with stdenv.lib; {
    description = "HTML5 parser and DOM library for Lua";
    homepage = https://craigbarnes.gitlab.io/lua-gumbo/;
    license = licenses.apache2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
