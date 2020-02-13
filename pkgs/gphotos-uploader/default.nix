{ stdenv, fetchFromGitLab, gradle, perl, makeWrapper
, git
, jre
}:

let
  version = "2019.07.20";
  plainName = "gphotos-uploader";
  className = "io.gitlab.rychly.gphotos_uploader.GPhotosUploader";
  name = "${plainName}-${version}";
  src = fetchFromGitLab {
    owner = "rychly";
    repo = "gphotos-uploader";
    rev = "04939dc4511a004fa95b75834f13f7dd";
    sha256 = "0dppy1v0xa7x2adlab7h39dmphwyca1y4ljia3gfj3giz9vpf1xl";
  };
  # fake build to pre-download deps into fixed-output derivation
  deps = stdenv.mkDerivation {	# cannot be a recursive derivation as we reffer to the name in the let
    name = "${name}-deps";
    inherit src;
    # disable fixupPhase as it can modify the resulting directory structure of the repository (e.g., move {man,doc,info} dirs into the share dir)
    phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];
    buildInputs = [ git gradle perl ];
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
    outputHash = "1q6wfdqf9b49mgm3z9zjigk45098q65ndxzxiankg2lx9k7fg4f6";
  };

in stdenv.mkDerivation rec {
  inherit name src;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ git gradle ];

  buildPhase = ''
    runHook preBuild
    export GRADLE_USER_HOME=$(mktemp -d)
    substituteInPlace build.gradle \
      --replace 'jcenter()' 'mavenLocal(); maven { url uri("${deps}") }'
    gradle --offline --no-daemon build --exclude-task test
    runHook postBuild
  '';

  preInstall = ''
    mkdir ./target
    tar -xf ./build/distributions/gphotos-uploader-*.tar -C ./target
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/java}
    mv ./target/*/lib/*.jar $out/share/java/	# move JARs from the distribution directory
    unset CLASSPATH
    for I in $out/share/java/*.jar; do
      CLASSPATH=$CLASSPATH''${CLASSPATH:+:}$I
    done
    makeWrapper ${jre}/bin/java $out/bin/${plainName} --add-flags "-cp $CLASSPATH ${className}"
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Uploads missing media files from given directories into Google Photos and control their sharing";
    inherit (src.meta) homepage;
    license = licenses.asl20;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
