{ stdenv, fetchFromGitHub, fetchurl, gradle, perl, makeWrapper
, jre
}:

let
  version = "2.1-snapshot-2018-09-05";
  name = "dex2jar-${version}";
  src = fetchFromGitHub {
    owner = "pxb1988";
    repo = "dex2jar";
    rev = "9cfc8ba805a98b4585bab1831b47b29969aa85e4";
    sha256 = "1d77d041nb1m5jbw9cgdh96x53c732k7zi5pzgshh5pqzcv1z132";
  };
  # fake build to pre-download deps into fixed-output derivation
  deps = stdenv.mkDerivation {	# cannot be a recursive derivation as we reffer to the name in the let
    name = "${name}-deps";
    inherit src;
    # disable fixupPhase as it can modify the resulting directory structure of the repository (e.g., move {man,doc,info} dirs into the share dir)
    phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];
    buildInputs = [ gradle perl ];
    buildPhase = ''
      runHook preBuild
      export GRADLE_USER_HOME=$(mktemp -d)
      gradle --no-daemon build --exclude-task test
      runHook postBuild
    '';
    # perl code mavenizes pathes (com.squareup.okio/okio/1.13.0/a9283170b7305c8d92d25aff02a6ab7e45d06cbe/okio-1.13.0.jar -> com/squareup/okio/okio/1.13.0/okio-1.13.0.jar)
    installPhase = ''
      runHook preInstall
      find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\)' \
        | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
        | sh
      runHook postInstall
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "1qbfh3bs8kclhmqrix71cbpkhxz2p5f3cwjpwj5lr3v7dsbsj4jd";
  };

in stdenv.mkDerivation rec {
  inherit name src;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ gradle ];

  buildPhase = ''
    runHook preBuild
    export GRADLE_USER_HOME=$(mktemp -d)
    substituteInPlace build.gradle \
      --replace 'mavenCentral()' 'mavenLocal(); maven { url uri("${deps}") }'
    gradle --offline --no-daemon build --exclude-task test
    runHook postBuild
  '';

  preInstall = ''
    mkdir ./target
    tar -xf ./dex-tools/build/distributions/dex-tools-*.tar -C ./target
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/java}
    cd ./target/*	# switch to the distribution directory
    mv ./lib/*.jar $out/share/java/
    unset CLASSPATH
    for I in $out/share/java/*.jar; do
      CLASSPATH=$CLASSPATH''${CLASSPATH:+:}$I
    done
    for I in d2j-*.sh; do	# must be just filenames without a path
      CLASSNAME=$(grep -o 'com\.googlecode\.[^\"]*' $I)
      makeWrapper ${jre}/bin/java $out/bin/''${I%.sh} \
        --add-flags "-cp $CLASSPATH $CLASSNAME"
    done
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/pxb1988/dex2jar;
    description = "Tools to work with android .dex and java .class files";
    license = licenses.asl20;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
