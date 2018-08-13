# adapted from https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/development/mobile/adbfs-rootless/default.nix
{ stdenv, fetchFromGitHub, fetchpatch, pkgconfig, fuse, adb }:

stdenv.mkDerivation rec {
  name = "adbfs-rootless-${version}";
  version = "2018-07-20";

  src = fetchFromGitHub {
    owner = "spion";
    repo = "adbfs-rootless";
    rev = "a8e1c7f4b561e1d77948e5d1d1ad58855bade183";
    sha256 = "1jhljf2sdd0qwvrd67ppbwxplj59v43nwqqr4rmclqd0r3qv3d3k";
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
