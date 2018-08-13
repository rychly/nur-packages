{ stdenv, fetchFromGitHub
, pythonPackages
}:

let
  version = "0.9";
in

pythonPackages.buildPythonApplication rec {

  name = "lingea-trd-decoder-${version}";

  src = fetchFromGitHub {
    owner = "PetrDlouhy";
    repo = "lingea-trd-decoder";
    rev = "80d5acb695b8c8ef109b49db59af6659d70bfc25";
    sha256 = "0z1psb6fylls88c1nh9vlyszkm3knfr8kh28xjklbm4501b6vdcm";
  };

  dontConfigure = true;
  dontBuild = true;
  doCheck = false;	# there are no tests (missing nix_run_setup executed by python)

  installPhase = ''
    runHook preInstall
    install -D -m 555 lingea-trd-decoder.py $out/bin/lingea-trd-decoder
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Scripts for decoding Lingea Dictionary (.trd) file";
    homepage = https://github.com/PetrDlouhy/lingea-trd-decoder;
    license = licenses.gpl2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
