{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib }:

with pkgs; rec {

  ## packages
  adbfs-rootless = callPackage ./pkgs/adbfs-rootless {
    adb = androidenv.platformTools;
  };
  ctstream = callPackage ./pkgs/ctstream { };
  des = callPackage ./pkgs/des { };
  dex2jar = callPackage ./pkgs/dex2jar { };
  dhcpcd-ui = callPackage ./pkgs/dhcpcd-ui { };
  dummydroid = callPackage ./pkgs/dummydroid { };
  dunstify-stdout = callPackage ./pkgs/dunstify-stdout { };
  esmska = callPackage ./pkgs/esmska { };
  flickcurl = callPackage ./pkgs/flickcurl { };
  getaddrinfo-tcp = callPackage ./pkgs/getaddrinfo-tcp { };
  googleearth = callPackage ./pkgs/googleearth { };
  h2status = callPackage ./pkgs/h2status { };
  hunspellDicts = recurseIntoAttrs {
    cs = callPackage ./pkgs/hunspell-dicts/ooa-cs.nix { };
  };
  imgrepackerrk = callPackage_i686 ./pkgs/imgrepackerrk { };
  ipmiview = callPackage ./pkgs/ipmiview { };
  jad = callPackage_i686 ./pkgs/jad { };
  konwert = callPackage ./pkgs/konwert { };
  libjpeg-extra = callPackage ./pkgs/libjpeg-extra { };
  lingea-trd-decoder = callPackage ./pkgs/lingea-trd-decoder { };
  modelio = callPackage ./pkgs/modelio {
    inherit xulrunner192;
    plugins = [];
  };
  modelio-plugins = recurseIntoAttrs {
    ba = callPackage ./pkgs/modelio-plugins/ba.nix { };
    sa = callPackage ./pkgs/modelio-plugins/sa.nix { };
    sd = callPackage ./pkgs/modelio-plugins/sd.nix { };
  };
  pan-baidu-download = callPackage ./pkgs/pan-baidu-download { };
  pass-git-helper = callPackage ./pkgs/pass-git-helper { };
  pass-menu = callPackage ./pkgs/pass-menu { };
  photo-mgmt = callPackage ./pkgs/photo-mgmt {
    inherit flickcurl;
  };
  raccoon4 = callPackage ./pkgs/raccoon/4.nix { };
  rajce-download = callPackage ./pkgs/rajce-download {};
  rkflashkit = callPackage ./pkgs/rkflashkit { };
  rkupgradetool = callPackage_i686 ./pkgs/rkupgradetool { };
  rockchip-mkbootimg = callPackage ./pkgs/rockchip-mkbootimg { };
  rofi-modi-mount = callPackage ./pkgs/rofi-modi-mount { };
  rofi-modi-vbox = callPackage ./pkgs/rofi-modi-vbox {
    inherit dunstify-stdout;
  };
  setlayout = callPackage ./pkgs/setlayout { };
  soapui = callPackage ./pkgs/soapui { };
  stardict-lingea-lexicon = callPackage ./pkgs/stardict-lingea-lexicon {
    inherit stardict-tools;
  };
  stardict-tools = callPackage ./pkgs/stardict-tools { };
  televize = callPackage ./pkgs/televize {
    inherit ctstream;
  };
  visualparadigm = callPackage ./pkgs/visualparadigm { };
  winbox = callPackage ./pkgs/winbox { };
  xerox-phaser-3250 = callPackage ./pkgs/xerox-phaser-3250 { };
  xulrunner192 = callPackage ./pkgs/xulrunner/1.9.2.nix { };
  youtube-api-samples-python = callPackage ./pkgs/youtube-api-samples-python { };

}
