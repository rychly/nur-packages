# adapted from https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/development/mobile/adbfs-rootless/default.nix
{ stdenv, fetchFromGitHub, fetchpatch, pkgconfig, fuse, adb }:

stdenv.mkDerivation rec {
  name = "adbfs-rootless-${version}";
  version = "2019.07.13";

  src = fetchFromGitHub {
    owner = "spion";
    repo = "adbfs-rootless";
    rev = "ba64c22dbd373499eea9c9a9d2a9dd1c";
    sha256 = "1ax4lqprdr5v4rlznkk5q6kn80shw3rfg3jjiwv0milwxv3rl4cb";
  };

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ fuse ];

  postPatch = ''
    # very ugly way of replacing the adb calls
    sed -e 's|"adb |"${stdenv.lib.getBin adb}/bin/adb |g' \
        -i adbfs.cpp
  '';

  installPhase = ''
    install -D adbfs $out/bin/adbfs
  '';

  meta = with stdenv.lib; {
    description = "Mount Android phones on Linux with adb, no root required";
    inherit (src.meta) homepage;
    license = licenses.bsd3;
    maintainers = with maintainers; [ Profpatsch ];
    platforms = platforms.linux;
  };
}
