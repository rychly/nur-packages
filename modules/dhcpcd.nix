{ config, lib, ... }:

with lib;

let

  cfg = config.rychly.dhcpcd;

  ## modules

  mainModuleOptions = {

    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable dhcpcd configuration for individual interfaces.";
    };

    interfaces = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "A list of interfaces that should be configured with dhcp.";
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

in {

  options.rychly.dhcpcd = mainModuleOptions;

  config = mkIf (cfg.enable) {

    # disable default DHCP for all interfaces and enable it for named interfaces only
    # (which is a preferred way according to the networking.useDHCP option description)
    networking.useDHCP = false;
    networking.interfaces = lib.genAttrs cfg.interfaces (interface: { useDHCP = true; });

    # DHCP client
    networking.dhcpcd = {
      enable = true;	# Enabled by default, just to remind me this is the DHCP client (not systemd)
      #allowInterfaces = [ ];	# this is set automatically for all interfaces with enabled networking.interfaces.*.useDHCP
      denyInterfaces = [ "vmnet*" ];	# "vboxnet*" already in defaults, see https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/dhcpcd.nix
      extraConfig = ""
        + (lib.optionalString (cfg.slaac != null) "slaac ${cfg.slaac}\n")
        + (lib.optionalString (!cfg.ip4all) "noipv4ll\n")
      ;
    };

  };

}
