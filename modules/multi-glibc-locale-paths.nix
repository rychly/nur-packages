{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.custom.multiGlibcLocalePaths;

  # A random Nixpkgs revision *before* the default glibc
  # was switched to version 2.27.x (version <= 18.03).
  oldpkgs = pkgs;

  # A random Nixpkgs revision *after* the default glibc
  # was switched to version 2.27.x (version > 18.03).
  # sudo nix-channel --add "http://nixos.org/channels/nixpkgs-unstable" nixpkgs-unstable
  # sudo nix-channel --update nixpkgs-unstable
  newpkgs = import <nixpkgs-unstable> { };

  theLatestOldVersion = "18.03";

in {

  options.custom.multiGlibcLocalePaths = mkOption {
    type = types.bool;
    default = (builtins.compareVersions config.system.stateVersion theLatestOldVersion) != 1;	# value 1 (newer than) -> values are -1 (older than) or 0 (equal to)
    description = "Provide version-specific <code>LOCALE_ARCHIVE</code> environment variables to mitigate the effects of <a href=\"https://github.com/NixOS/nixpkgs/issues/38991\">issue 38991</a>.";
  };

  config = mkIf (cfg) {

    environment.sessionVariables = {
      LOCALE_ARCHIVE_2_21 = "${oldpkgs.glibcLocales}/lib/locale/locale-archive";
      LOCALE_ARCHIVE_2_27 = "${newpkgs.glibcLocales}/lib/locale/locale-archive";
    };

  };

}
