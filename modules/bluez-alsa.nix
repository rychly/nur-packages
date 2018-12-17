{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.bluealsa;

  pkgs-custom = import ../pkgs { inherit pkgs; };

  # FIXME: non-root user would not have access to DBus org.bluez
  # so we would need to add https://aur.archlinux.org/cgit/aur.git/tree/bluealsa.install?h=bluez-alsa-git
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
      default = pkgs-custom.bluez-alsa;
      description = "The bluez-alsa package which should be utilized, see https://github.com/Arkq/bluez-alsa.";
    };

  };

in {

  options.rychly.bluealsa = mainModuleOptions;

  config = mkIf (cfg.enable) {

    environment.systemPackages = [ pkgs-custom.bluez-alsa-tools ];

    # adapted from https://aur.archlinux.org/cgit/aur.git/tree/bluealsa.service?h=bluez-alsa-git
    systemd.services.bluealsa = {
      description = "BluezAlsa proxy";
      wantedBy = [ "multi-user.target" ];
      requires = [ "bluetooth.service" ];
      after = [ "bluetooth.service" ];
      preStart = "rm /run/bluealsa/* 2>/dev/null || true";
      serviceConfig = {
        User = user;
        Group = group;
        ExecStart = "${cfg.package}/bin/bluealsa";
      };
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
      <${cfg.package}/share/alsa/alsa.conf.d/20-bluealsa.conf>
    '';

  };

}
