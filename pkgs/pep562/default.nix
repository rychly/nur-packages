{ stdenv, fetchFromGitHub
, pythonPackages
}:

let
  pname = "pep562";
  version = "1.0.0";
  #pythonPackages = python2Packages;
in

pythonPackages.buildPythonPackage {

  inherit pname version;

  src = fetchFromGitHub {
    owner = "facelessuser";
    repo = pname;
    rev = version;
    sha256 = "1bhhq4s0cxsxbcpj0yi97h5dv620jf3cmwkjpfcc4143dcgx6f8g";
  };

  meta = with stdenv.lib; {
    description = "A backport of PEP 562.";
    homepage = https://github.com/facelessuser/pep562;
    license = licenses.mit;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
