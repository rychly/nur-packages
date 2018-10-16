{ stdenv, requireFile, dpkg
, version, fileName, sha256, abbr, description, homepage
}:

let
  versionParts = builtins.split "build" version;
  versionMain = builtins.elemAt versionParts 0;
  versionMainParts = builtins.splitVersion versionMain;
  versionMajor = builtins.elemAt versionMainParts 0 + "." + builtins.elemAt versionMainParts 1;
  versionMajorDash = builtins.elemAt versionMainParts 0 + "-" + builtins.elemAt versionMainParts 1;
  versionBuild = builtins.elemAt versionParts 2;	# idx 2, not idx 1 which is an empty list for the separator
  #version = "A.B.CbuildYYYYMMDDHHMM";	# from dpkg:/control file, Version attribute
  abbrLower = stdenv.lib.toLower abbr;
in

stdenv.mkDerivation rec {

  name = "modelio-${abbrLower}-${version}";

  # for referring in the modelio wrapper
  inherit versionMajor;

  src = requireFile rec {
    name = fileName;
    url = "https://www.modeliosoft.com/en/downloads/modeliosoft-products/modelio-${versionMajorDash}-x.html";
    inherit sha256;
    message = ''
      This Nix expression requires that ${name} already be part of the store. To
      obtain it you need to

      - navigate to ${url}
      - download "Modelio ${abbr} ${versionMain} - Debian"
      - sign in or create an Modelio account if neccessary

      and then add the file to the Nix store using either:
        nix-store --add-fixed sha256 ${name}
      or
        nix-prefetch-url --type sha256 file:///path/to/${name}
    '';
  };

  nativeBuildInputs = [ dpkg ];

  unpackCmd = ''
    mkdir root && dpkg-deb --fsys-tarfile $curSrc \
    | tar -xf - --wildcards --to-stdout './usr/share/modelio-by-modeliosoft-solutions${versionMajor}/modelio-*-product${versionMajor}.tar' \
    | tar -xf - --no-same-owner --directory=root	# unpack only the internal archive and unpack it directly without saving it
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/modelio-by-modeliosoft${versionMajor}
    mv ./* $out/lib/modelio-by-modeliosoft${versionMajor}/
    chmod 644 $out/lib/modelio-by-modeliosoft${versionMajor}/modules/*.jmdac $out/lib/modelio-by-modeliosoft${versionMajor}/templates/*.template
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    inherit description;
    inherit homepage;
    license = licenses.unfree;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };

  passthru = {
    inherit src;	# to prevent removal of the src from nix-store
  };
}
