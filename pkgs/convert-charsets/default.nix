{ stdenv, buildLuaPackage, fetchgit, wrapLua
}:

let
  version = "2019.05.06";
in

buildLuaPackage {

  name = "convert-charsets-${version}";

  src = fetchgit {
    url = "https://gitlab.com/rychly/convert-charsets.git";
    rev = "6dd2a16aa2a80589dad0f66806d654ff148540e4";
    sha256 = "085v9g6k5gaks92k7pfjb4lsnsq1pkl2md6l1c0i85xa6ajnw2d8";
  };

  buildInputs = [ wrapLua ];

  postFixup = ''
    wrapLuaPrograms
  '';

  meta = with stdenv.lib; {
    description = "Lua scripts to convert strings between UTF-8 and other charsets and from UTF-8 to ASCII";
    homepage = https://gitlab.com/rychly/convert-charsets;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    hydraPlatforms = stdenv.lib.platforms.linux;
  };
}
