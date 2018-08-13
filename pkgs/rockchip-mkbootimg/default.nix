{ stdenv, fetchFromGitHub
, openssl
}:

let
  version = "2016.09.19";
in

stdenv.mkDerivation rec {

  name = "rockchip-mkbootimg-${version}";

  src = fetchFromGitHub {
    owner = "niamster";
    repo = "rockchip-mkbootimg";
    rev = "afc440fd5e71d0af656a510662721ace9d5db35a";
    sha256 = "1hy39j7g3ay2vvg70j8pn4n5ngiz15if67r5x5vi8qb6gpnp3fhg";
  };

  buildInputs = [ openssl ];

  postPatch = ''
    # disable a compilation of 32-bit objects that requires the 32-bit glibc package, see https://gcc.gnu.org/wiki/FAQ#gnu_stubs-32.h
    # and do not use the install path prefix after a destination directory
    substituteInPlace Makefile \
      --replace " -m32" "" \
      --replace "/\$(PREFIX)/" "/"
  '';

  makeFlagsArray = [ "DESTDIR=$(out)" ];

  meta = with stdenv.lib; {
    description = "Tools to create firmware and boot images for Rockchip devices";
    homepage = https://github.com/niamster/rockchip-mkbootimg;
    license = licenses.asl20;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
