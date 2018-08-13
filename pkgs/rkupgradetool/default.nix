{ stdenv_32bit, fetchurl, unzip
}:

let
  version = "1.21";
in

stdenv_32bit.mkDerivation rec {

  name = "rkupgradetool-${version}";

  src = fetchurl {
    url = "http://dl.radxa.com/rock/tools/linux/Linux_Upgrade_Tool_v${version}.zip";
    sha256 = "6d8c14beb411beada4d65b055a9ae5b143fd1fc597629b8d946f25b50a68698a";
  };

  nativeBuildInputs = [ unzip ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 ./upgrade_tool $out/bin/rkupgradetool
    runHook postInstall
  '';

  meta = with stdenv_32bit.lib; {
    description = "Rockchip tools for update.img, parameter, bootloader and other partitions";
    homepage = "http://wiki.radxa.com/Rock/flash_the_image#Upgrade_tool_from_Rockchip";
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
