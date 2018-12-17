{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.boot;

  ## modules

  mainModuleOptions = {

    platform = mkOption {
      type = types.nullOr (types.enum [ "bios" "efi" ]);
      default = null;
      description = "Boot platform to enable a corresponding boot-loader: BIOS, EFI, or unset (<code>null</code> value to skip the boot-loader configuration).";
    };

    extra = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra configuration of NixOS <code>boot</code> option.";
    };

  };

in {

  options.rychly.boot = mainModuleOptions;

  config = {

    boot = recursiveUpdateUntil (path: l: r: path == [ "loader" ]) {
      loader = {
        timeout = 1;
      } // optionalAttrs (cfg.platform == "efi") {
        systemd-boot = {
          enable = true;
          editor = true;	# allow editing the kernel command-line before boot
        };
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";	# kernel and initramfs images will be in EFI directories
        };
      } // optionalAttrs (cfg.platform == "bios") {
        grub = {
          enable = true;
          device = "/dev/sda";
          enableCryptodisk = true;
        };
      };
    } cfg.extra;

  };

}
