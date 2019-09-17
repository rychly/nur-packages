{ stdenv, fetchurl, patchelf, makeWrapper, gcc-unwrapped
, jre
}:

let
  sha256 = {
    "i686-linux" = "0d2qmw3hggq7fdkly557gcivfvk6l39brq208yhd171b8rcr9f6y";
    "x86_64-linux" = "0qw9zfnj0cyvab7ndamlw2y0gpczjhh1jkz8340kl42r2xmhkvpl";
  }.${stdenv.system};
  plat = {
    "i686-linux" = "Linux";
    "x86_64-linux" = "Linux_x64";
  }.${stdenv.system};
  versionParts = builtins.split "build" version;
  versionMain = builtins.elemAt versionParts 0;
  versionBuild = builtins.elemAt versionParts 2;	# idx 2, not idx 1 which is an empty list for the separator
  version = "2.16.0build190815";
in

stdenv.mkDerivation rec {

  name = "ipmiview-${version}";

  src = fetchurl {
    url = "ftp://ftp.supermicro.com/utility/IPMIView/Linux/IPMIView_${versionMain}_build.${versionBuild}_bundleJRE_${plat}.tar.gz";
    inherit sha256;
  };

  nativeBuildInputs = [ makeWrapper patchelf ];
  buildInputs = [ jre ];

  postUnpack = ''
    # delete non-linux platform files, bundled JRE, and launcher scripts and configuration (lax) files
    rm -rf $sourceRoot/BMCSecurity/{mac,win} $sourceRoot/jre $sourceRoot/*.{lax,dll}
    egrep -R --null --files-with-matches "^#!.*/bin/" $sourceRoot | xargs --null rm
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/java,lib/ipmiview,share/doc/ipmiview}
    mv ./*.jar $out/share/java
    mv ./*.{pdf,txt} $out/share/doc/ipmiview
    mv ./* $out/lib/ipmiview
    makeWrapper ${jre}/bin/java $out/bin/ipmiview \
      --add-flags "-Djava.library.path=$out/lib/ipmiview -jar $out/share/java/IPMIView20.jar"
    makeWrapper ${jre}/bin/java $out/bin/jviewerx9 \
      --add-flags "-Djava.library.path=$out/lib/ipmiview -jar $out/share/java/JViewerX9.jar"
    makeWrapper ${jre}/bin/java $out/bin/trapreceiver \
      --add-flags "-Djava.library.path=$out/lib/ipmiview -jar $out/share/java/TrapView.jar"
    makeWrapper ${jre}/bin/java $out/bin/ikvm \
      --add-flags "-Djava.library.path=$out/lib/ipmiview -jar $out/share/java/iKVM.jar"
    makeWrapper ${jre}/bin/java $out/bin/ikvm-microblade \
      --add-flags "-Djava.library.path=$out/lib/ipmiview -jar $out/share/java/iKVMMicroBlade.jar"
    runHook postInstall
  '';

  preFixup = ''
    patchelf --set-rpath "${gcc-unwrapped.lib}/lib" --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/lib/ipmiview/BMCSecurity/linux/stunnel32
    patchelf --set-rpath "${gcc-unwrapped.lib}/lib" --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/lib/ipmiview/BMCSecurity/linux/stunnel64
    patchelf --set-rpath "${gcc-unwrapped.lib}/lib" $out/lib/ipmiview/libiKVM32.so
    patchelf --set-rpath "${gcc-unwrapped.lib}/lib" $out/lib/ipmiview/libiKVM64.so
  '';

  meta = with stdenv.lib; {
    description = "SuperMicro IPMI management tool";
    homepage = ftp://ftp.supermicro.com/utility/IPMIView/Linux/;
    license = licenses.unfree;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
