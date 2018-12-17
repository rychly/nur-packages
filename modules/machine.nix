{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.machine;

  lib-custom = import ../lib { inherit lib; };

  ## modules

  mainModuleOptions = {

    name = mkOption {
      type = types.str;
      description = "The full name of the machine (e.g., hostname.domain).";
    };

    sysAdminEmail = mkOption {
      type = types.nullOr (types.strMatching "([^,@]+@[^,@]+)");
      default = null;
      description = "Email address of a system administrator to forward root's emails.";
    };

    setHostNameAndDomain = mkOption {
      type = types.bool;
      default = true;
      description = "Set <code>networking.hostName</code> and <code>networking.domain</code> according to <code>name<code> attribute."
        + " The host name and domain should not be set in some cases, e.g., if you want to obtain it from a DHCP server (if using DHCP).";
    };

    numLockOn = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Turns on (true) or off (false) the numlock key in X sessions. Null value does not affect the numlock key state.";
    };

    systemPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "The set of packages (for this machine) that appear in <code>/run/current-system/sw</code>."
        + " These packages are automatically available to all users, and are automatically updated every time you rebuild the system configuration.";
    };

    etcFilesMatch = {

      separator = mkOption {
        type = types.str;
        default = "=";
        description = "Separator for matching the suffix in filenames of etc files.";
      };

      suffix = mkOption {
        type = types.nullOr types.str;
        default = lib-custom.hostNameFromName cfg.name;
        description = "Required suffix, e.g., the name of the machine, for etc files if there is the separator in their filenames.";
      };

    };

    etcFilesDirs = mkOption {
      type = types.listOf (types.either types.path types.str);
      default = [ ];
      description = "List of directories (by paths or strings; paths are stored in a public nix-store, strings are not stored and can be in a secure path)."
        + " The content of the directories will be symlinked to the etc directory by <code>environment.etc</code>.";
    };

    udev = mkOption {
      type = types.attrs;
      default = { };
      description = "Configuration of NixOS <code>services.udev</code> option, e.g., to set extra rules of HW database.";
    };

  };

in {

  options.rychly.machine = mainModuleOptions;

  config = {

    # host name and domain
    networking.hostName = mkIf (cfg.setHostNameAndDomain) (lib-custom.hostNameFromName cfg.name);
    networking.domain = let
      domain = lib-custom.domainFromName cfg.name;
    in mkIf (cfg.setHostNameAndDomain && (domain != null)) domain;

    # system administrator email
    networking.defaultMailServer.root = mkIf (cfg.sysAdminEmail != null) cfg.sysAdminEmail;

    # numlock
    services.xserver.displayManager.sessionCommands = mkIf (cfg.numLockOn != null) (mkAfter ''
      ${pkgs.numlockx}/bin/numlockx ${if cfg.numLockOn then "on" else "off"}
    '');

    # system packages
    environment.systemPackages = cfg.systemPackages;

    # etc files
    environment.etc = lib-custom.targetSourceFilesFromDirs cfg.etcFilesDirs cfg.etcFilesMatch.separator cfg.etcFilesMatch.suffix;

    # udev
    services.udev = cfg.udev;

    #
    assertions = [
      {
        assertion = (cfg.name != "");
        message = "Name of the machine must not be empty.";
      }
    ];

  };

}
