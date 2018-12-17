{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.mount;

  ## modules

  mainModuleOptions = {

    fs = mkOption {
      type = types.attrs;
      default = { };
      description = "Configuration of NixOS <code>fileSystems</code> option.";
    };

    swap = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "Configuration of NixOS <code>swapDevices</code> option.";
    };

    udisks = mkOption {
      type = types.nullOr (types.enum [ false true "global" "user" ]);
      default = "user";
      description = "Whether to enable Udisks (<code>true</code> or <code>false</code>; <code>null</code> value to skip) and if enabled, where to create mount-points:"
        + " in a global shared directory (<code>/media/VolumeName</code>; which should be on tmpfs), or in a user private directory (<code>/run/media/$USER/VolumeName</code>; which is on tmpfs).";
    };

  };

  ## shortcuts

  udisksEnabled = (cfg.udisks != null) && (cfg.udisks != false);	# not null or false -> true, or string to select the location to mountpoints
  udisksSetShare = builtins.isString cfg.udisks;	# string -> either "global" or "user" to set sharing

in {

  options.rychly.mount = mainModuleOptions;

  config = {

    fileSystems = cfg.fs;

    swapDevices = cfg.swap;

    services.udisks2.enable = mkIf (cfg.udisks != null) udisksEnabled;
    services.udev.extraRules = mkIf (udisksSetShare) ''
      # UDISKS_FILESYSTEM_SHARED
      # ==0: mount filesystem to a private directory (/run/media/$USER/VolumeName) which is on tmpfs
      # ==1: mount filesystem to a shared directory (/media/VolumeName) which should be on tmpfs
      # See udisks(8), https://wiki.archlinux.org/index.php/Udisks#Mount_to_.2Fmedia_.28udisks2.29
      ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="${if (cfg.udisks == "user") then "0" else "1"}"
    '';

  };

}
