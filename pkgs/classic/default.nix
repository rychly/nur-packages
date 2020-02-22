{ stdenv, buildLuarocksPackage, fetchurl
}:

let
  version = "0.1.0-1";
in

buildLuarocksPackage {

  inherit version;

  pname = "classic";

  src = fetchurl {
    url = "https://luarocks.org/manifests/emartech/classic-${version}.src.rock";
    sha256 = "0xbqwszlyn00qc4chzqsria02rli0hxg3yv53izi5giaqcnmjd0s";
  };

  buildType = "builtin";

  meta = with stdenv.lib; {
    description = "Tiny class module for Lua";
    homepage = https://github.com/emartech/classic;
    license = licenses.mit;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
