{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.bluealsa;

  # FIXME: non-root user would not have access to DBus org.bluez
  # so we would need to add https://aur.archlinux.org/cgit/aur.git/tree/bluealsa.install?h=bluez-alsa
  # into /etc/dbus-1 which is already managed by config.services.dbus.packages and we have no package to do this
  user = "root";
  group = "audio";

  ## modules

  mainModuleOptions = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and enable the Bluetooth Audio ALSA Backend.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.bluez-alsa;	# from rychly/nixpkgs-public
      description = "The bluez-alsa package which should be utilized, see https://github.com/Arkq/bluez-alsa.";
    };

  };

in {

  options.rychly.bluealsa = mainModuleOptions;

  config = mkIf (cfg.enable) {

    environment.systemPackages = [
      pkgs.bluez-alsa-tools	# from rychly/nixpkgs-public
    ];

    services.dbus.packages = [ cfg.package ];

    # adapted from https://github.com/Arkq/bluez-alsa/wiki/Systemd-integration#service-unit-file
    systemd.services.bluealsa = {
      description = "Bluealsa daemon";
      documentation = [ "https://github.com/Arkq/bluez-alsa/" ];
      after = [ "dbus-org.bluez.service" ];
      requires = [ "dbus-org.bluez.service" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.bluealsa";
        ExecStart = "${cfg.package}/bin/bluealsa";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        RemoveIPC = true;
        RestrictAddressFamilies = "AF_UNIX AF_BLUETOOTH";
        # also non-privileged can user be used, see ${cfg.package}/share/dbus-1/system.d/bluealsa.conf
        User = user;
        Group = group;
      };
      wantedBy = [ "bluetooth.target" ];
      preStart = "rm /run/bluealsa/* 2>/dev/null || true";
    };

    # adapted from https://aur.archlinux.org/cgit/aur.git/tree/bluealsa.tmpfiles?h=bluez-alsa-git
    # legacy directory updated: /var/run/bluealsa to /run/bluealsa
    systemd.tmpfiles.rules = [ "d /run/bluealsa 0755 ${user} ${group} -" ];

    environment.etc."asound.conf".text = ''
      ctl_type.bluealsa {
        libs.native = ${cfg.package}/lib/alsa-lib/libasound_module_ctl_bluealsa.so ;
      }
      pcm_type.bluealsa {
        libs.native = ${cfg.package}/lib/alsa-lib/libasound_module_pcm_bluealsa.so ;
      }
      <${cfg.package}/etc/alsa/conf.d/20-bluealsa.conf>
    '';

  };

}
