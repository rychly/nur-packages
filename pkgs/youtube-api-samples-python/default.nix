{ stdenv, fetchFromGitHub, makeWrapper
, python2Packages
}:

let
  inherit (python2Packages) python;
  version = "2018.04.26";
in

python2Packages.buildPythonApplication rec {

  name = "youtube-api-samples-python-${version}";

  src = fetchFromGitHub {
    owner = "youtube";
    repo = "api-samples";
    rev = "07263305b59a7c3275bc7e925f9ce6cabf774022";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  propagatedBuildInputs = with python2Packages; [ google-api-python-client google-auth ];

  dontConfigure = true;
  dontBuild = true;
  doCheck = false;	# there are no tests (missing nix_run_setup executed by python)

  installPhase = let
    pythonSiteDir = "${python.sitePackages}";
  in ''
    runHook preInstall
    mkdir -p $out/${pythonSiteDir}
    cp ${src}/python/*.py $out/${pythonSiteDir}/
    for I in $out/${pythonSiteDir}/*.py; do
      _basename=$(basename $I .py) _name=youtube_''${_basename/yt_/}
      makeWrapper ${python.interpreter} $out/bin/$_name \
        --set PYTHONPATH "$PYTHONPATH:$(toPythonPath $out)" \
        --add-flags $I
    done
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    broken = true;
    description = "Code samples for YouTube APIs in Python, including the YouTube Data API, YouTube Analytics API, and YouTube Live Streaming API";
    homepage = https://github.com/youtube/api-samples/tree/master/python;
    license = licenses.asl20;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
