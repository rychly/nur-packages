{ stdenv, requireFile, autoPatchelfHook, fixDarwinDylibNames, unzip, libaio, makeWrapper, odbcSupport ? false, unixODBC }:

assert odbcSupport -> unixODBC != null;

let
  inherit (stdenv.lib) optional optionals optionalString;

  version = "18.3.0.0.0dbru_18.5.0.0.0dbru";
  versionArchs = builtins.split "_" version;
  myVersion = {
    "i686-linux" = builtins.elemAt versionArchs 0;
    "x86_64-linux" = builtins.elemAt versionArchs 2;	# idx 2, not idx 1 which is an empty list for the separator
  }."${stdenv.hostPlatform.system}" or throwSystem;
  versionParts = builtins.splitVersion myVersion;
  baseVersion = builtins.elemAt versionParts 0 + "." + builtins.elemAt versionParts 1;

  requireSource = component: arch: version: rel: hash: (requireFile rec {
    name = "instantclient-${component}-${arch}-${version}" + (optionalString (rel != "") "-${rel}") + ".zip";
    url = "http://www.oracle.com/technetwork/database/database-technologies/instant-client/downloads/index.html";
    sha256 = hash;
  });

  throwSystem = throw "Unsupported system: ${stdenv.hostPlatform.system}";

  arch = {
    "i686-linux" = "linux";
    "x86_64-linux" = "linux.x64";
  }."${stdenv.hostPlatform.system}" or throwSystem;

  srcs = {
    "i686-linux" = [
      (requireSource "basic" arch myVersion "2" "1ggg3hf89vxmbqdcbcldz1gdr4i2himrxazpg23sbp23b3r2y8w1")
      (requireSource "sdk" arch myVersion "2" "08w44k3jnp5iq0j9l772fgq39xdjny7f07m34axb2xp9ckm762j1")
      (requireSource "sqlplus" arch myVersion "2" "15ckc83i5xqiadl4i9092r347f2px8if9q88gz0xw9ah376k4lr0") ]
      ++ optional odbcSupport (requireSource "odbc" arch myVersion "2" "1ppjhh12plc81ikngw4h2mjfq7md9jja2px29y811vpw8blyl5kf");
    "x86_64-linux" = [
      (requireSource "basic" arch myVersion "" "1mw5dp7rgp02sgqhfvy8bzjs1p3gwapknf7kf5fq9q6pw9w6gblx")
      (requireSource "sdk" arch myVersion "" "191zjcy1cw83hmwgzlhanmvbsn35bvwcb4w6s2iidri48acgrg1b")
      (requireSource "sqlplus" arch myVersion "" "09360fb2kicgm5827333p6pjc6szh5994h0ija72083s1y4d94af") ]
      ++ optional odbcSupport (requireSource "odbc" arch myVersion "2" "08jqfwyk5hs393c0xbxh1bd8ilq6p0nc8zr34qyw7012hbqvgx3n");
  }."${stdenv.hostPlatform.system}" or throwSystem;

  extLib = stdenv.hostPlatform.extensions.sharedLibrary;
in stdenv.mkDerivation rec {
  inherit version srcs;
  name = "oracle-instantclient-${version}";

  buildInputs = [ stdenv.cc.cc.lib ]
    ++ optionals (stdenv.isLinux) [ libaio ]
    ++ optional odbcSupport unixODBC;

  nativeBuildInputs = [ makeWrapper unzip ]
    ++ optional stdenv.isLinux autoPatchelfHook
    ++ optional stdenv.isDarwin fixDarwinDylibNames;

  unpackCmd = "unzip $curSrc";

  installPhase = ''
    mkdir -p "$out/"{bin,include,lib,"share/java","share/${name}/demo/"}
    install -Dm755 {sqlplus,adrci,genezi} $out/bin
    ${optionalString stdenv.isDarwin ''
      for exe in "$out/bin/"* ; do
        install_name_tool -add_rpath "$out/lib" "$exe"
      done
    ''}
    ln -sfn $out/bin/sqlplus $out/bin/sqlplus64
    install -Dm644 *${extLib}* $out/lib
    install -Dm644 *.jar $out/share/java
    install -Dm644 sdk/include/* $out/include
    install -Dm644 sdk/demo/* $out/share/${name}/demo

    # PECL::oci8 will not build without this
    # this symlink only exists in dist zipfiles for some platforms
    ln -sfn $out/lib/libclntsh${extLib}.${baseVersion} $out/lib/libclntsh${extLib}
  '';

  meta = with stdenv.lib; {
    description = "Oracle instant client libraries and sqlplus CLI";
    longDescription = ''
      Oracle instant client provides access to Oracle databases (OCI,
      OCCI, Pro*C, ODBC or JDBC). This package includes the sqlplus
      command line SQL client.
    '';
    license = licenses.unfree;
    platforms = [ "x86_64-linux" "i686-linux" ];
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    hydraPlatforms = [];
  };
}
