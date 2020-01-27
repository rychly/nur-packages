{ stdenv, fetchFromGitHub
, pythonPackages
, mkdocs, pymdown-extensions
}:

let
  pname = "mkdocs-material";
  version = "4.1.1";
  # version > 4.1.1 have setup.py using open(file, encoding) which is Python3, however, mkdocs is in Python2
  #pythonPackages = python3Packages;
in

pythonPackages.buildPythonPackage {

  inherit pname version;

  src = fetchFromGitHub {
    owner = "squidfunk";
    repo = pname;
    rev = version;
    sha256 = "15qhhc4f6p90x1asqdsgdjfzilb66h95kxgd8scpfgvq2c4h0hjg";
  };

  nativeBuildInputs = [ mkdocs ];
  propagatedBuildInputs = with pythonPackages; [ pygments pymdown-extensions ];

  meta = with stdenv.lib; {
    description = "A Material Design theme for MkDocs.";
    homepage = https://squidfunk.github.io/mkdocs-material;
    license = licenses.mit;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
