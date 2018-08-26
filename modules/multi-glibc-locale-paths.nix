{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.rychly.multiGlibcLocalePaths;

  lib-custom = import ../lib { inherit pkgs; };

  # A random Nixpkgs revision *before* the default glibc
  # was switched to version 2.27.x (version <= 18.03).
  oldpkgs = pkgs;

  # A random Nixpkgs revision *after* the default glibc
  # was switched to version 2.27.x (version >= 18.09).
  newpkgs = lib-custom.pkgs-in-version pkgs "18.09";

in {

  options.rychly.multiGlibcLocalePaths = mkOption {
    type = types.bool;
    default = (lib-custom.pkgs-version oldpkgs) != (lib-custom.pkgs-version newpkgs);	# if newpkgs is different from (i.e., newer than) oldpkgs
    description = "Provide version-specific <code>LOCALE_ARCHIVE</code> environment variables to mitigate the effects of <a href=\"https://github.com/NixOS/nixpkgs/issues/38991\">issue 38991</a>.";
  };

  config = mkIf (cfg) {

    environment.sessionVariables = {
      LOCALE_ARCHIVE_2_21 = "${oldpkgs.glibcLocales}/lib/locale/locale-archive";
      LOCALE_ARCHIVE_2_27 = "${newpkgs.glibcLocales}/lib/locale/locale-archive";
    };

  };

}
