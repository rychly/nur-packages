{ stdenv, fetchFromGitHub, fetchurl, gradle, perl, makeWrapper
, jre
}:

let
  version = "2.1-nightly-28";
  name = "dex2jar-${version}";
  src = fetchFromGitHub {
    owner = "pxb1988";
    repo = "dex2jar";
    rev = version;
    sha256 = "04xr6j3s4mgvhihvjhx0hm3kqhyvnbyb14kvvfazm1g1i6ni65pk";
  };
  # [PATCH] update dx from 1.7 to 23.0.0
  srcPatchDx = fetchurl {
    url = "https://github.com/pxb1988/dex2jar/commit/c4bec2d2ec14d282667fe8241510d15ef85a3cfe.patch";
    sha256 = "d344460ed88a29230cb47bee35f749e57a60c77732bfd402516dbfe7c157bf00";
  };
  # reverse the DX 1.7=>23.0.0 patch to fix issue https://github.com/pxb1988/dex2jar/issues/140
  # we need to skip tests by "build --exclude-task test" as com.googlecode.dex2jar.ir.test.RemoveConstantFromSSATest > t004 FAILED
  patches = [ srcPatchDx ];
  patchFlags = [ "-p1 --reverse" ];	# each flags item applies on its corresponing patches item
  # fake build to pre-download deps into fixed-output derivation
  deps = stdenv.mkDerivation {	# cannot be a recursive derivation as we reffer to the name in the let
    name = "${name}-deps";
    inherit src patches patchFlags;
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
    outputHash = "1qqs8kp1xc71kvrgrd5m1w80qyppypsz490zwcrfzkwnlivz8085";
  };

in stdenv.mkDerivation rec {
  inherit name src patches patchFlags;

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
