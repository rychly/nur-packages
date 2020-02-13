{ stdenv, fetchFromGitHub, makeWrapper
, python2Packages, aria2
}:

let
  inherit (python2Packages) python;
  version = "2018.10.30";
in

python2Packages.buildPythonApplication rec {

  name = "pan-baidu-download-${version}";

  src = fetchFromGitHub {
    owner = "sdvcrx";
    repo = "pan-baidu-download";
    rev = "5bd559b2178be63995a5cfc5066a5df4";
    sha256 = "13nbbkn3k22ljggkhz5m8dh6gn8lq55icwvbx9wpayfdm984jxxc";
  };

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = with python2Packages; [ requests ];

  postPatch = ''
    substituteInPlace ./command/download.py \
      --replace aria2c ${aria2}/bin/aria2c
    # change a storage location to temp directory
    sed -i \
      -e 's/^\(import util\)$/\1\nimport tempfile/' \
      -e 's/os\.path\.abspath(__file__)/os.path.join(tempfile.gettempdir(), "none")/g' \
      ./bddown_core.py ./command/login.py
    # change config.ini location
    sed -i \
      -e 's/\(self\._path =\).*$/\1os.path.join(os.path.expanduser("~"), ".pan-baidu-download")/' \
      -e 's/config.ini/.pan-baidu-download/g' \
      -e "s|\\(No such file: [^'\"]*\\)|\\1\\\\nRun: cp $out/etc/pan-baidu-download ~/.pan-baidu-download|" \
      ./command/config.py
  '';

  dontConfigure = true;
  dontBuild = true;
  doCheck = false;	# there are no tests (missing nix_run_setup executed by python)

  installPhase = let
    pythonSiteDir = "${python.sitePackages}/pan-baidu-download";
  in ''
    runHook preInstall
    mkdir -p $out/etc $out/${pythonSiteDir}
    mv ./config.ini $out/etc/pan-baidu-download
    mv *.py command $out/${pythonSiteDir}/
    makeWrapper ${python.interpreter} $out/bin/pan-baidu-download \
      --set PYTHONPATH "$PYTHONPATH:$(toPythonPath $out)" \
      --add-flags $out/${pythonSiteDir}/bddown_cli.py
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Baidu network disk download script";
    homepage = https://github.com/banbanchs/pan-baidu-download;
    license = licenses.mit;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
