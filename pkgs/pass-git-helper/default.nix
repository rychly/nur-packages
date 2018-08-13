{ stdenv, fetchFromGitHub
, python3Packages }:

let
  version = "0.4";
in

python3Packages.buildPythonApplication rec {

  name = "pass-git-helper-${version}";

  src = fetchFromGitHub {
    owner = "languitar";
    repo = "pass-git-helper";
    rev = "release-${version}";
    sha256 = "1dcj6wgmwcg3ahl5xm23wfqnqrywxlbz5wbwh7dq4qaw4qabir5x";
  };

  propagatedBuildInputs = with python3Packages; [ pyxdg ];

  meta = with stdenv.lib; {
    description = "A git credential helper interfacing with pass, a standard unix password manager";
    homepage = https://github.com/languitar/pass-git-helper;
    license = licenses.lgpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
