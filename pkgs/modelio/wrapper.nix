{ modelio
, plugins, symlinkJoin }:

symlinkJoin {
  name = "modelio-with-plugins-${modelio.version}";

  paths = [ modelio ] ++ plugins;

  postBuild = ''
    # modelio wrapper will use the original gtkrc-modelio, so its symlink is not needed
    rm $out/lib/modelio-by-modeliosoft${modelio.versionMajor}/gtkrc-modelio
  '';
}
