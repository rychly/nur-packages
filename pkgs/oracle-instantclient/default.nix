{ stdenv, requireFile, autoPatchelfHook, fixDarwinDylibNames, unzip, libaio, makeWrapper, odbcSupport ? false, unixODBC }:

assert odbcSupport -> unixODBC != null;

let
  inherit (stdenv.lib) optional optionals optionalString;

  version = "19.3.0.0.0dbru_19.3.0.0.0dbru";
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
      (requireSource "basic" arch myVersion "2" "0rns440v0biak7n3y36fipigi0mh9917hiblda2qf37a4k06ms5b")
      (requireSource "sdk" arch myVersion "2" "1gza6jnraqd6d951x6d4bm792w8cahn7h51r4q2jqm53cp3nxdi1")
      (requireSource "sqlplus" arch myVersion "2" "0nl9kk18sw45nj5hnn5fnicbdg6rxs9gp2z8qwqzwmrs3jcnqyv3") ]
      ++ optional odbcSupport (requireSource "odbc" arch myVersion "2" "06bs63bawa2mkzaiifrwvslniz4wj3fswc8dqq4rr0z1a6p2wjk3");
    "x86_64-linux" = [
      (requireSource "basic" arch myVersion "" "1yk4ng3a9ka1mzgfph9br6rwclagbgfvmg6kja11nl5dapxdzaxy")
      (requireSource "sdk" arch myVersion "" "115v1gqr0czy7dcf2idwxhc6ja5b0nind0mf1rn8iawgrw560l99")
      (requireSource "sqlplus" arch myVersion "" "0zj5h84ypv4n4678kfix6jih9yakb277l9hc0819iddc0a5slbi5") ]
      ++ optional odbcSupport (requireSource "odbc" arch myVersion "2" "1g1z6pdn76dp440fh49pm8ijfgjazx4cvxdi665fsr62h62xkvch");
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
