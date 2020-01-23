{ stdenv, fetchFromGitHub
, pythonPackages
, pep562
}:

let
  pname = "pymdown-extensions";
  version = "6.2.1";
  #pythonPackages = python3Packages;
in

pythonPackages.buildPythonPackage {

  inherit pname version;

  src = fetchFromGitHub {
    owner = "facelessuser";
    repo = pname;
    rev = version;
    sha256 = "1rd2zwmg5f9x7nsh7v8mx2ddgl8b7fp6rvswjb8qm0fvakyw6wx3";
  };

  nativeBuildInputs = with pythonPackages; [ markdown ];
  propagatedBuildInputs = [ pep562 ];

  doCheck = false;	# tests have another requirements: pytest yaml

  meta = with stdenv.lib; {
    description = "Extensions for Python Markdown.";
    homepage = https://github.com/facelessuser/pymdown-extensions;
    license = licenses.mit;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
