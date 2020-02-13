{ stdenv, buildLuarocksPackage, luaOlder, luaAtLeast, fetchurl
, dbus
}:

let
  version = "2019-08-16";
in

buildLuarocksPackage {

  inherit version;

  pname = "ldbus";

  # cannot use fetchFromGtiHub as the buildLuarocksPackage needs an unextracted ZIP file
  src = fetchurl {
    url = "https://github.com/daurnimator/ldbus/archive/9e176fe851006037a643610e6d8f3a8e597d4073.zip";
    sha256 = "0nqb46mij4jb69ya2a956lwji0yjacap1hip84bid7z4fi20xx55";
  };

  disabled = ( luaOlder "5.1" ) || ( luaAtLeast "5.4" );
  buildInputs = [ dbus.dev dbus.lib ];
  buildType = "builtin";

  rockspecFilename = "../ldbus-scm-0.rockspec";

  extraVariables = ''
    DBUS_INCDIR="${dbus.dev}/include/dbus-1.0"
    DBUS_ARCH_DIR="${dbus.lib}/lib/dbus-1.0"
  '';

  # FIXME: try again with newer luarocks as now,
  # there is an error "../fs.lua:78: attempt to call local 'each_platform' (a nil value)"
  # fixed by https://github.com/luarocks/luarocks/pull/1083

  meta = with stdenv.lib; {
    description = "Lua Bindings to dbus";
    homepage = https://github.com/daurnimator/ldbus;
    license = licenses.mit;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
