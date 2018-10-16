{ pkgs ? import <nixpkgs> { } }:

with pkgs; rec {

  ## packages
  # Only packages should be here, e.g., not lists, sets, etc. of packages as those cannot be detected by `../non-broken-and-unfree.nix` (i.e., do not use `pkgs.recurseIntoAttrs`).

  adbfs-rootless = callPackage ./adbfs-rootless {
    adb = androidenv.platformTools;
  };
  ctstream = callPackage ./ctstream { };
  des = callPackage ./des { };
  dex2jar = callPackage ./dex2jar { };
  dhcpcd-ui = callPackage ./dhcpcd-ui { };
  dummydroid = callPackage ./dummydroid { };
  dunstify-stdout = callPackage ./dunstify-stdout { };
  esmska = callPackage ./esmska { };
  flickcurl = callPackage ./flickcurl { };
  getaddrinfo-tcp = callPackage ./getaddrinfo-tcp { };
  googleearth = callPackage ./googleearth { };
  h2status = callPackage ./h2status { };
  hunspellDictCs = callPackage ./hunspell-dicts/ooa-cs.nix { };
  imgrepackerrk = callPackage_i686 ./imgrepackerrk { };
  jad = callPackage_i686 ./jad { };
  konwert = callPackage ./konwert { };
  libjpeg-extra = callPackage ./libjpeg-extra { };
  lingea-trd-decoder = callPackage ./lingea-trd-decoder { };
  modelio36 = callPackage ./modelio/default36.nix {
    inherit xulrunner192;
    plugins = [];
  };
  modelio-plugin-ba36 = callPackage ./modelio-plugins/ba36.nix { };
  modelio-plugin-sa36 = callPackage ./modelio-plugins/sa36.nix { };
  modelio-plugin-sd36 = callPackage ./modelio-plugins/sd36.nix { };
  modelio37 = callPackage ./modelio/default37.nix {
    inherit xulrunner192;
    plugins = [];
  };
  modelio-plugin-ba37 = callPackage ./modelio-plugins/ba37.nix { };
  modelio-plugin-sa37 = callPackage ./modelio-plugins/sa37.nix { };
  modelio-plugin-sd37 = callPackage ./modelio-plugins/sd37.nix { };
  modelio38 = callPackage ./modelio/default38.nix {
    inherit xulrunner192;
    plugins = [];
  };
  modelio-plugin-ba38 = callPackage ./modelio-plugins/ba38.nix { };
  modelio-plugin-sa38 = callPackage ./modelio-plugins/sa38.nix { };
  modelio-plugin-sd38 = callPackage ./modelio-plugins/sd38.nix { };
  pan-baidu-download = callPackage ./pan-baidu-download { };
  pass-git-helper = callPackage ./pass-git-helper { };
  pass-menu = callPackage ./pass-menu { };
  photo-mgmt = callPackage ./photo-mgmt {
    inherit flickcurl;
  };
  raccoon4 = callPackage ./raccoon/4.nix { };
  rajce-download = callPackage ./rajce-download {};
  rclonefs = callPackage ./rclonefs { };
  rkflashkit = callPackage ./rkflashkit { };
  rkupgradetool = callPackage_i686 ./rkupgradetool { };
  rockchip-mkbootimg = callPackage ./rockchip-mkbootimg { };
  rofi-modi-mount = callPackage ./rofi-modi-mount { };
  rofi-modi-vbox = callPackage ./rofi-modi-vbox {
    inherit dunstify-stdout;
  };
  setlayout = callPackage ./setlayout { };
  soapui = callPackage ./soapui { };
  stardict-lingea-lexicon = callPackage ./stardict-lingea-lexicon {
    inherit stardict-tools;
  };
  stardict-tools = callPackage ./stardict-tools { };
  televize = callPackage ./televize {
    inherit ctstream;
  };
  visualparadigm = callPackage ./visualparadigm { };
  winbox = callPackage ./winbox { };
  xerox-phaser-3250 = callPackage ./xerox-phaser-3250 { };
  xulrunner192 = callPackage ./xulrunner/1.9.2.nix { };
  #youtube-api-samples-python = callPackage ./youtube-api-samples-python { };	# DISABLED: requires python/google-api-python-client which is not in v18.03, see https://github.com/NixOS/nixpkgs/commits/master/pkgs/development/python-modules/google-api-python-client
  zenstates = callPackage ./zenstates { };

}
