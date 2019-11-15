{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib, lib-custom ? import ../lib { inherit lib; }}:

with pkgs; let

  # to apply the jre/jdk below, the variables must be inherited in callPackage (otherwise, the callPackage use jre/jdk from pkgs)
  # jdk: maven/gradle/etc. (not ant) usually use they own jdk (their built-time dependencies), so it does not make sense to inherit jdk
  jre = oraclejdk;
  jdk = oraclejdk;

in rec {

  ## packages
  # Only packages should be here, e.g., not lists, sets, etc. of packages as those cannot be detected by `../non-broken-and-unfree.nix` (i.e., do not use `pkgs.recurseIntoAttrs`).

  adbfs-rootless = callPackage ./adbfs-rootless {
    adb = androidenv.androidPkgs_9_0.platform-tools;
  };
  bluez-alsa = callPackage ./bluez-alsa { };
  bluez-alsa-tools = callPackage ./bluez-alsa-tools { };
  convert-charsets = callPackage ./convert-charsets {
    inherit (pkgs.luaPackages) buildLuaPackage luaOlder wrapLua;
  };
  ctstream = callPackage ./ctstream { };
  des = callPackage ./des {
    inherit jre;
  };
  dex2jar = callPackage ./dex2jar {
    inherit jre;
  };
  dhcpcd-ui = callPackage ./dhcpcd-ui { };
  dummydroid = callPackage ./dummydroid {
    inherit jre;
  };
  dunstify-stdout = callPackage ./dunstify-stdout { };
  esmska = callPackage ./esmska {
    inherit jre jdk;
  };
  flickcurl = callPackage ./flickcurl { };
  getaddrinfo-tcp = callPackage ./getaddrinfo-tcp { };
  gphotos-uploader = callPackage ./gphotos-uploader {
    inherit jre;
  };
  h2status = callPackage ./h2status { };
  hunspellDictCs = callPackage ./hunspell-dicts/ooa-cs.nix { };
  imgrepackerrk = callPackage_i686 ./imgrepackerrk { };
  ipmiview = callPackage ./ipmiview {
    inherit jre;
  };
  jad = callPackage_i686 ./jad { };
  konwert = callPackage ./konwert { };
  libjpeg-extra = callPackage ./libjpeg-extra { };
  lingea-trd-decoder = callPackage ./lingea-trd-decoder { };
  luaspell = callPackage ./luaspell {
    inherit (pkgs.luaPackages) buildLuarocksPackage luaOlder;
  };
  luasql-oci8 = callPackage ./luasql-oci8 {
    inherit (pkgs.luaPackages) buildLuarocksPackage luaOlder;
    inherit oracle-instantclient;
  };
  luaxmlrpc = callPackage ./luaxmlrpc {
    inherit (pkgs.luaPackages) buildLuarocksPackage luaOlder luaAtLeast luaexpat luasocket;
  };
  mail-parser = callPackage ./mail-parser {
    inherit (pkgs.luaPackages) buildLuaPackage luaOlder wrapLua luafilesystem luasocket;
    inherit convert-charsets;
  };
  modelio36 = callPackage ./modelio/default36.nix {
    inherit jre;
    inherit xulrunner192;
    plugins = [];
    # fixed https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=898960 and https://github.com/gentoo/gentoo/
    # load gtk2 including pango-1.43.0 from v19.09 or Git master
    gtk2 = (lib-custom.pkgs-in-version pkgs "19.09").gtk2;
  };
  modelio-plugin-ba36 = callPackage ./modelio-plugins/ba36.nix { };
  modelio-plugin-sa36 = callPackage ./modelio-plugins/sa36.nix { };
  modelio-plugin-sd36 = callPackage ./modelio-plugins/sd36.nix { };
  modelio37 = callPackage ./modelio/default37.nix {
    inherit jre;
    inherit xulrunner192;
    plugins = [];
  };
  modelio-plugin-ba37 = callPackage ./modelio-plugins/ba37.nix { };
  modelio-plugin-sa37 = callPackage ./modelio-plugins/sa37.nix { };
  modelio-plugin-sd37 = callPackage ./modelio-plugins/sd37.nix { };
  modelio38 = callPackage ./modelio/default38.nix {
    inherit jre;
    inherit xulrunner192;
    plugins = [];
  };
  modelio-plugin-ba38 = callPackage ./modelio-plugins/ba38.nix { };
  modelio-plugin-sa38 = callPackage ./modelio-plugins/sa38.nix { };
  modelio-plugin-sd38 = callPackage ./modelio-plugins/sd38.nix { };
  oracle-instantclient = callPackage ./oracle-instantclient { };
  pan-baidu-download = callPackage ./pan-baidu-download { };
  pass-git-helper = callPackage ./pass-git-helper { };
  pass-menu = callPackage ./pass-menu { };
  photo-mgmt = callPackage ./photo-mgmt {
    inherit flickcurl;
  };
  pyglossary = callPackage ./pyglossary {
    withGtk3 = true;
  };
  pyglossaryNoGui = callPackage ./pyglossary {
    withGtk3 = false;
  };
  raccoon4 = callPackage ./raccoon/4.nix {
    inherit jre;
  };
  rajce-download = callPackage ./rajce-download {};
  rclonefs = callPackage ./rclonefs { };
  rkflashkit = callPackage ./rkflashkit { };
  rkupgradetool = callPackage_i686 ./rkupgradetool { };
  rockchip-mkbootimg = callPackage ./rockchip-mkbootimg { };
  rofi-modi-mount = callPackage ./rofi-modi-mount { };
  rofi-modi-vbox = callPackage ./rofi-modi-vbox {
    inherit dunstify-stdout;
  };
  sandbox = callPackage ./sandbox { };
  setlayout = callPackage ./setlayout { };
  soapui = callPackage ./soapui {
    inherit jre;
  };
  sqldeveloper = callPackage ./sqldeveloper {
    inherit jre;
  };
  stardict-lingea-lexicon = callPackage ./stardict-lingea-lexicon {
    inherit stardict-tools pyglossaryNoGui;
    withStardictTools = false;
    withPyGlossary = true;
  };
  stardict-tools = callPackage ./stardict-tools { };
  televize = callPackage ./televize {
    inherit ctstream;
  };
  visualparadigm = callPackage ./visualparadigm {
    inherit jre;
  };
  winbox = callPackage ./winbox { };
  xerox-phaser-3250 = callPackage ./xerox-phaser-3250 { };
  xulrunner192 = callPackage ./xulrunner/1.9.2.nix { };
  #youtube-api-samples-python = callPackage ./youtube-api-samples-python { };	# DISABLED: requires python/google-api-python-client which is not in v18.03, see https://github.com/NixOS/nixpkgs/commits/master/pkgs/development/python-modules/google-api-python-client
  zenstates = callPackage ./zenstates { };

}
