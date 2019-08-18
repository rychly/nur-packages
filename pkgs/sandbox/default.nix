{ stdenv, fetchgit
, autoreconfHook, bash }:

stdenv.mkDerivation rec {
  name = "sandbox-${version}";
  version = "2.18";

  src = fetchgit {
    url = "https://anongit.gentoo.org/git/proj/sandbox.git";
    rev = "v${version}";
    sha256 = "0xkvb3xpjrkjj002dd1c01jhmgmhd5s8xqfarrylvpls7j73xr56";
  };

  nativeBuildInputs = [ autoreconfHook ];

  postPatch = ''
    for I in ./data/sandbox.bashrc ./src/sandbox.c; do
      substituteInPlace "$I" --replace /bin/bash "${bash}/bin/bash"
    done
  '';

  meta = with stdenv.lib; {
    description = "Sandbox is a library (and helper utility) to run programs in a "sandboxed" environment.";
    homepage = https://wiki.gentoo.org/wiki/Project:Sandbox;
    license = licenses.gpl2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
