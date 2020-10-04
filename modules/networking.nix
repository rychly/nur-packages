{ config, lib, ... }:

with lib;

let

  cfg = config.rychly.networking;

  ## modules

  mainModuleOptions = {

    dhcpcd = {

      interfaces = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "A list of interfaces that should be configured with dhcpd.";
      };

      slaac = mkOption {
        type = types.nullOr (types.enum [ "hwaddr" "private" ]);
        default = "private";	# use HW address based IPv6 addresses for each network interface (not common stable DUID for all interfaces)
        description = "Use private (an RFC7217 address) or HW (a MAC address) interface identifier used for SLAAC generated IPv6 addresses.";
      };

      ip4all = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to use IPv4LL (aka APIPA, aka Bonjour, aka ZeroConf).";
      };

    };

    supplicant = {

      interfaces = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "A list of interfaces that should be configured with wpa_supplicant.";
      };

      conf = mkOption {
        type = types.nullOr (types.either types.path types.str);
        default = null;
        description = "<code>/path/to/wpa_supplicant.conf</code> as of path or string datatype.";
      };

    };

  };

in {

  options.rychly.networking = mainModuleOptions;

  config = {

    # disable default DHCP for all interfaces and enable it for named interfaces only
    # (which is a preferred way according to the networking.useDHCP option description)
    networking.useDHCP = mkIf (cfg.dhcpcd.interfaces != []) false;
    networking.interfaces = let attrs = {
      useDHCP = true;
    }; in lib.genAttrs cfg.dhcpcd.interfaces (interface: attrs);

    # DHCP client
    networking.dhcpcd = mkIf (cfg.dhcpcd.interfaces != []) {
      enable = true;	# Enabled by default, just to remind me this is the DHCP client (not systemd)
      #allowInterfaces = [ ];	# this is set automatically for all interfaces with enabled networking.interfaces.*.useDHCP
      denyInterfaces = [ "vmnet*" ];	# "vboxnet*" already in defaults, see https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/dhcpcd.nix
      wait = "if-carrier-up";	# wait only for enabled interfaces (i.e., do not wait for unplugged USB modems)
      extraConfig = ""
        + (lib.optionalString (cfg.dhcpcd.slaac != null) "slaac ${cfg.dhcpcd.slaac}\n")
        + (lib.optionalString (!cfg.dhcpcd.ip4all) "noipv4ll\n")
      ;
    };

    # WPA Supplicant
    networking.supplicant = let attrs = {
      configFile.path = mkIf (cfg.supplicant.conf != null) cfg.supplicant.conf;	# if empty wpa_supplicant will use nixos options to generate the configuration file, i.e., won't use not /etc/wpa_supplicant.conf file
      userControlled.enable = true;	# enabled only for wpa_supplicant to control it via wpa_cli/wpa_gui
    }; in lib.genAttrs cfg.supplicant.interfaces (interface: attrs);

  };

}
