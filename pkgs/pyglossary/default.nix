{ stdenv, fetchFromGitHub, makeWrapper
, python37Packages
, withGtk3 ? true, gnome3 ? null
}:

let
  pythonPackages = python37Packages;
  inherit (pythonPackages) python;
  pname = "pyglossary";
  version = "3.2.0-snapshot-2019.06.12";
in

pythonPackages.buildPythonApplication {

  inherit pname version;

  src = fetchFromGitHub {
    owner = "ilius";
    repo = pname;
    rev = "c62c2eb796964a83c8f88a3c39d0662af7a1d816";
    sha256 = "1l4ps0b3nh0rpj48l2d0i1n3q6j0mij0qsc9g748mfm8kq7s8j28";
  };

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = with pythonPackages; [ beautifulsoup4 ]
    ++ stdenv.lib.optionals (withGtk3) [ pythonPackages.pygobject3 pythonPackages.pycairo gnome3.gobject-introspection gnome3.gtk3 ];

  dontConfigure = true;
  dontBuild = true;
  doCheck = false;	# there are no tests (missing nix_run_setup executed by python)

  installPhase = ''
    runHook preInstall
    ${python.interpreter} ./setup.py install --prefix="$out" || exit 1
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "A tool for converting dictionary files aka glossaries with various formats for different dictionary applications.";
    homepage = https://github.com/ilius/pyglossary;
    license = licenses.gpl3;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
