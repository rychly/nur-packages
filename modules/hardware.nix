{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.hardware;

  ## modules

  mainModuleOptions = {

    backlight = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable backlight control.";
    };

    bluetooth = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable support for Bluetooth.";
    };

    chipsetVendors = mkOption {
      type = types.listOf (types.enum [ "intel-cpu" "amd-cpu" "intel-gpu" "amd-gpu" "ati-gpu" "nvidia-gpu" ]);
      default = [ ];
      description = "List of supported chipset vendors: Intel and AMD for CPUs and GPUs; ATI and NVidia for GPUs; etc.";
    };

    nvidiaGpuDriver = mkOption {
      type = types.enum [ "nouveau" "nvidia" "nvidiaLegacy340" "nvidiaLegacy304" "nvidiaLegacy173" ];
      default = "nouveau";
      description = "Type of open-source or current/legacy proprietary driver for NVidia GPUs (ignored for non-NVidia GPUs).";
    };

    cpuCores = mkOption {
      type = types.ints.positive;
      default = 1;
      description = "Number of CPU cores for parallel building.";
    };

    lidSwitch = mkOption {
      default = "suspend";
      type = types.enum [ "ignore" "poweroff" "reboot" "halt" "kexec" "suspend" "hibernate" "hybrid-sleep" "lock" ];
      description = "Specifies what to be done when the laptop lid is closed.";
    };

    powerKey = mkOption {
      default = null;
      type = types.nullOr (types.enum [ "ignore" "poweroff" "reboot" "halt" "kexec" "suspend" "hibernate" "hybrid-sleep" "lock" ]);
      description = "Specifies how to handle the system power to trigger actions such as system power-off or suspend.";
    };

    powersaving = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable powersaving.";
    };

    smart = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable S.M.A.R.T. monitoring system.";
    };

    sound = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable support for soundcards.";
    };

    ssd = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable SSD optimizations (tmpfs, profile-sync-daemon, etc.).";
    };

  };

in {

  options.rychly.hardware = mainModuleOptions;

  config = {

    programs.light.enable = mkIf (cfg.backlight) true;
    services.udev.extraRules = mkIf (cfg.backlight) ''
      # Give video group backlight control permissions
      SUBSYSTEM=="backlight", \
        RUN+="${pkgs.coreutils}/bin/chown :video /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power", \
        RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power"
    '';

    hardware.bluetooth = mkIf (cfg.bluetooth) {
      enable = true;
      powerOnBoot = false;
    };

    hardware.cpu = builtins.listToAttrs (
      map (vendor: nameValuePair (removeSuffix "-cpu" vendor) { updateMicrocode = true; }) (
        builtins.filter (vendor: (vendor == "intel-cpu") || (vendor == "amd-cpu"))	# updateMicrocode only for Intel and AMD CPUs
        cfg.chipsetVendors
      )
    );
    hardware.opengl.extraPackages = flatten (map (vendor:
      if (vendor == "intel-gpu") then [
        pkgs.vaapiIntel	# Intel VA-API
        pkgs.libvdpau-va-gl	# the VDPAU driver with VA-API/OpenGL backend (e.g., for Adobe Flash Player and Mplayer; since there is no VDPAU available on Intel chips)
        pkgs.intel-ocl	# Official Intel OpenCL runtime
      ]
      else if (vendor == "nvidia-gpu") then [
        pkgs.vaapiVdpau	# HW video decode support in the VAAPI library for VDPAU platforms. e.g. NVIDIA
      ]
      else [ ]) cfg.chipsetVendors
    );
    services.xserver.videoDrivers = flatten (map (vendor:
      if (vendor == "intel-gpu") then [
        "intel"	# Intel open-source video driver
      ]
      else if (vendor == "amd-gpu") then [
        "ati_unfree"	# AMD/ATI proprietary video driver
      ]
      else if (vendor == "ati-gpu") then [
        "ati"	# AMD/ATI free video driver
      ]
      else if (vendor == "nvidia-gpu") then [
        cfg.nvidiaGpuDriver	# NVIDIA proprietary video driver of particular type (current or legacy)
      ]
      else [ ]) cfg.chipsetVendors
    );
    hardware.nvidia.modesetting = mkIf ((any (vendor: vendor == "nvidia-gpu") cfg.chipsetVendors) && (cfg.nvidiaGpuDriver == "nvidia")) {
      enable = true;
    };
    virtualisation.virtualbox.guest = mkIf (any (vendor: vendor == "vbox") cfg.chipsetVendors) {
      enable = true;
    };

    nix.maxJobs = cfg.cpuCores;
    nix.buildCores = 0;
    zramSwap.numDevices = cfg.cpuCores;

    services.logind.lidSwitch = cfg.lidSwitch;
    services.logind.extraConfig = mkIf (cfg.powerKey != null) ''
      HandlePowerKey=${cfg.powerKey}
    '';

    powerManagement.cpuFreqGovernor = mkIf (cfg.powersaving) (lib.mkDefault "powersave");
    services.tlp.enable = mkIf (cfg.powersaving) true;	# For optimal power management (better than pmutils)

    services.smartd.enable = cfg.smart;

    sound.enable = cfg.sound;

    services.psd.enable = mkIf (cfg.ssd) true;	# web-browser Profile Sync daemon for SSD optimisation
    boot.tmpOnTmpfs = mkIf (cfg.ssd) true;

  };

}
