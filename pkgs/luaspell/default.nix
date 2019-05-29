{ stdenv, buildLuarocksPackage, luaOlder, fetchgit
, hunspell
}:

let

  version = "2019.05.29";

  src = fetchgit {
    url = "https://gitlab.com/rychly/luaspell.git";
    rev = "85224c45c40496ad18d245b1c58c09c1ca08d575";
    sha256 = "1zzwcsi8am83943ni8jk1h969298frv1ydg04n4jh42c71vily45";
  };

in buildLuarocksPackage {

  inherit version src;

  pname = "luaspell";

  knownRockspec = "${src.outPath}/luaspell-git-1.rockspec";

  disabled = ( luaOlder "5.1" );
  buildInputs = [ hunspell ];
  buildType = "cmake";

  preConfigure = ''
    HUNSPELL_LIBRARY="${hunspell.out}/lib"
  '';

  meta = with stdenv.lib; {
    description = "A Lua binding to the Hunspell spell checking engine";
    homepage = https://gitlab.com/rychly/luaspell;
    license = licenses.mit;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
