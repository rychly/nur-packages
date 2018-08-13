{ stdenv, fetchurl, pkgconfig, libX11
}:

let
  version = "1";
in

stdenv.mkDerivation rec {

  name = "setlayout-${version}";

  src = fetchurl {
    url = "http://openbox.org/dist/tools/setlayout.c";
    sha256 = "1ci9lq4qqhl31yz1jwwjiawah0f7x0vx44ap8baw7r6rdi00pyiv";
  };

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ libX11 ];

  unpackPhase = ''
    true	# it is already unpacked and the overriding unpackPhase will disable also the postUnpack phase and its default hooks (such as for sourceRoot)
  '';

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    gcc -O2 -o setlayout $(pkg-config --cflags --libs x11) $src;
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D -m 555 -t $out/bin/ setlayout
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "A small program to set X11 desktop layout";
    homepage = "http://openbox.org/wiki/Help%3aFAQ#How_do_I_put_my_desktops_into_a_grid_layout_instead_of_a_single_row.3F";
    license = licenses.gpl2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
