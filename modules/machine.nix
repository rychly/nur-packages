{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.machine;

  pkgs-custom = import ../pkgs { inherit pkgs; };

  ## modules

  userModule = types.submodule {

    options = {

      addToUsersUsers = mkOption {
        type = types.bool;
        default = true;
        description = "Add <code>nixOsUser</code> attributes into <code>config.users.users</code> to define the user in NixOs (recommended to disable for system users, e.g., for the 'root' user).";
      };

      nixOsUser = mkOption {
        type = types.attrs;	# FIXME: it is the type of users.users.*
        description = "NixOS definition of the user according to the configuration option <code>users.users</code>.";
      };

      fullName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Full name of the user.";
      };

      email = mkOption {
        type = types.nullOr (types.strMatching "([^,@]+@[^,@]+)");
        default = null;
        description = "Email address of the user.";
      };

      key = mkOption {
        type = types.nullOr (types.strMatching "([0-9A-F]+)");
        default = null;
        description = "GPG key number of the user.";
      };

      homeFilesDirs = mkOption {
        type = types.listOf (types.either types.path types.str);
        default = [ ];
        description = "List of directories (by paths or strings; paths are stored in a public nix-store, strings are not stored and can be in a secure path)."
          + " The content of the directories will be symlinked to the home directory of the user by <code>home-manager.users.*.home.file</code>.";
      };

    };

  };

  printerModule = types.submodule {

    options = {

      name = mkOption {
        type = types.str;
        description = "Name of the printer in CUPS.";
      };

      model = mkOption {
        type = types.str;
        description = "Model definition of the printer as a PPD file. Available values can be listed by: <code>lpinfo -m | grep modelNumber\code>";
      };

      driver = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "Driver package which provides a PPD file with the model definition (otherwise, there will be lpadmin error 'Unable to copy PPD file').";
        example = "pkgs.hplip";
      };

      deviceUri = mkOption {
        type = types.str;
        description = "URI of the printer's device, e.g.: <code>usb://Vendor/PrinterModel?serial=XXXX</code>, <code>socket://printerhostname</code>, or <code>smb://$(grep '^username=' ${smbCredentials} | cut -d = -f 2):$(grep '^password=' ${smbCredentials} | cut -d = -f 2)@smbhostname/smbprintername</code>";
      };

      info = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Description of the printer.";
      };

      location = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Description of the location of the printer.";
      };

      options = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Printer options. Available values can be listed by: <code>lpoptions -p printerName -l</code>";
        example = [ "PageSize=A4" "Duplex=DuplexNoTumble" ];
      };

    };

  };

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
          default = hostNameFromName cfg.name;
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

      hardware = {

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
          type = types.listOf (types.enum [ "intel" "amd" "nvidia" ]);
          default = [ ];
          description = "List of supported chipset vendors: Intel, AMD, NVidia, etc.";
        };

        cpuCores = mkOption {
          type = types.ints.positive;
          default = 1;
          description = "Number of CPU cores for parallel building.";
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

        wifi = mkOption {
          type = types.either types.bool (types.either types.path types.str);
          default = false;
          description = "Whether to enable support for WiFi (<code>false</code> disabled;"
            + " <code>true</code> for Network Manager; <code>/path/to/wpa_supplicant.conf</code> as of path or string datatype for WPA Supplicant).";
        };

      };

      boot = {

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

      mount = {

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

      printing = {

        printers = mkOption {
          type = types.listOf printerModule;
          default = [ ];
          description = "Printers for CUPS.";
        };

        defaultPrinter = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "CUPS name of the default printer.";
        };

        webInterfaceUsers = mkOption {
          type = types.listOf types.str;
          default = [ "@SYSTEM" ];
          description = "If not empty, restrict access to the CUPS web interface to a list of user-name or @group-name items.";
        };

      };

      users = mkOption {
        type = types.listOf userModule;
        default = [ ];
        description = "Additional user accounts to be created automatically by the system. This can also be used to set options for root.";
      };

      usersExtraGroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "The list of extra groups of the users.";
      };

      usersHomeFilesMatch = {

        separator = mkOption {
          type = types.str;
          default = "=";
          description = "Separator for matching the suffix in filenames of both user-specific home files.";
        };

        suffix = mkOption {
          type = types.nullOr types.str;
          default = hostNameFromName cfg.name;
          description = "Required suffix, e.g., the name of the machine, for user-specific home files if there is the separator in their filenames.";
        };

      };

      mainUser = {

        name = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Name of the main (non-root) user.";
        };

        autoLoginMingetty = mkOption {
          type = types.bool;
          default = false;
          description = "The main user will be automatically logged in at the console.";
        };

        autoLoginXserver = mkOption {
          type = types.bool;
          default = false;
          description = "The main user will be automatically logged in at the display manager.";
        };

      };

      home-manager = mkOption {
        type = types.unspecified;	# FIXME: the unspecified is lambda (user: type of home-manager.users)
        default = user: { };
        description = "A function <code>user: { ... }</code> to set home-manager attributes for each defined user.";
      };

      homeFiles = mkOption {
        type = types.attrsOf types.unspecified;	# FIXME: the unspecified is lambda (user: types.attrs, i.e., the type of home-manager.users.*.home.file)
        default = { };
        description = "Attribute set where the attribute values are functions <code>user: { ... }</code> returning home-manager home files to link link those files into each user home.";
      };

      gui = {

        sway = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable the tiling Wayland compositor Sway.";
        };

        xserver = mkOption {
          type = types.bool;
          default = (cfg.gui.displayManager != null) || (cfg.gui.windowManager != null) || (cfg.gui.desktopManager != null);
          description = "Whether to enable the X server.";
        };

        displayManager = mkOption {
          type = types.nullOr (types.enum [ "auto" "gdm" "lightdm" "sddm" "slim" "xpra"]);
          default = null;
          description = "Display manager to enable.";
        };

        windowManager = mkOption {
          type = types.nullOr (types.enum [ "i3" "fluxbox" ]);
          default = null;
          description = "Window manager to enable.";
        };

        desktopManager = mkOption {
          type = types.nullOr (types.enum [ "gnome3" "lxqt" "mate" "plasma5" "xfce" ]);
          default = null;
          description = "Desktop manager to enable.";
        };

      };

  };

  ## helpers

  # split a name to its host name and domain parts
  parseNameToHostNameDomain = name: builtins.match "([^.]+)(.(.+))?" name;
  hostNameFromName = name: builtins.head (parseNameToHostNameDomain name);
  domainFromName = name: builtins.elemAt (parseNameToHostNameDomain name) 2;

  # remove extra-item and intra-item separators from a password item
  sanitizePasswdItem = passwdItem: builtins.replaceStrings [ ":" "," ] [ "" "" ] passwdItem;

  # create attrs for environment.etc or home-manager.users.*.home.file for all files in a given directory structure (optionaly, the resulting files will be based in a given path)
  targetSourceFilesFromDirs = dirs: suffixSeparator: suffix: let
    dirDeepFilesHierarchy = dir: base: mapAttrsToList (name: value:
      let
        nameString = toString name;
        splitName = splitString suffixSeparator nameString;
        isSuffixOk = ((builtins.tail splitName) == [ ]) || ((builtins.head (builtins.tail splitName)) == suffix);
        isIgnoredFile = (substring 0 1 nameString == ".") || (hasSuffix ".gpg" nameString) || (hasSuffix ".example" nameString);
        nameAsStringWithBase = if (base == "") || (base == ".") then (builtins.head splitName) else "${base}/${builtins.head splitName}";
      in
        # an empty set for the non-matching item
        if (! isSuffixOk) then { }
        # a sub-list for items of the matching sub-directory
        else if value == "directory"
        then dirDeepFilesHierarchy (dir + "/${name}") nameAsStringWithBase
        # an empty set for ignored files (not directories; e.g., .gitignore, ecrypted *.gpg, examples *.example)
        else if isIgnoredFile then { }
        # an item (not a list) for the matching file
        else {
          source = dir + "/${name}";	# the source is a path, i.e., it will be in a nix-store
          target = nameAsStringWithBase;
        }
    ) (builtins.readDir dir);
    desanitizeFileName = path: let	# desanitize illegal filenames such as starting with "." which is represented by the initial "-"
      pathWithoutInitialDot = removePrefix "-" path;
    in if (pathWithoutInitialDot != path) then ".${pathWithoutInitialDot}" else path;
  in builtins.listToAttrs (map (pathPair: nameValuePair (desanitizeFileName pathPair.target) { inherit (pathPair) source; }) (
    # skip empty sets generated by non-matching items
    builtins.filter (set: set != { }) (flatten (map (dir: dirDeepFilesHierarchy dir ".") dirs)))
  );

  ## shortcuts

  wifiEnabled = cfg.hardware.wifi != false;	# not false -> true, or a path (or string of the path) to wpa_supplicant.conf
  wifiWpaSupplicant = ! builtins.isBool cfg.hardware.wifi;	# not bool -> is the path (or string of the path) to wpa_supplicant.conf
  wifiNetworkManager = cfg.hardware.wifi == true;	# true -> not a path to not wpa_supplicant.conf

  udisksEnabled = (cfg.mount.udisks != null) && (cfg.mount.udisks != false);	# not null or false -> true, or string to select the location to mountpoints
  udisksSetShare = builtins.isString cfg.mount.udisks;	# string -> either "global" or "user" to set sharing

  printingEnabled = cfg.printing.printers != [ ];

in {

  options.rychly.machine = mainModuleOptions;

  config = mkMerge [ {	# merge list items as if they were declared in separate modules

    # host name and domain
    networking.hostName = mkIf (cfg.setHostNameAndDomain) (hostNameFromName cfg.name);
    networking.domain = let
      domain = domainFromName cfg.name;
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
    environment.etc = targetSourceFilesFromDirs cfg.etcFilesDirs cfg.etcFilesMatch.separator cfg.etcFilesMatch.suffix;

    # udev
    services.udev = cfg.udev;

    #
    assertions = [
      {
        assertion = (cfg.name != "");
        message = "Name of the machine must not be empty.";
      }
    ];

  } {

    ## hardware

    programs.light.enable = mkIf (cfg.hardware.backlight) true;
    services.udev.extraRules = mkIf (cfg.hardware.backlight) ''
      # Give video group backlight control permissions
      SUBSYSTEM=="backlight", \
        RUN+="${pkgs.coreutils}/bin/chown :video /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power", \
        RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power"
    '';

    hardware.bluetooth = mkIf (cfg.hardware.bluetooth) {
      enable = true;
      powerOnBoot = false;
    };

    hardware.cpu = builtins.listToAttrs (
      map (vendor: nameValuePair vendor { updateMicrocode = true; }) (
        builtins.filter (vendor: (vendor == "intel") || (vendor == "amd"))	# updateMicrocode only for Intel and AMD CPUs
        cfg.hardware.chipsetVendors
      )
    );
    hardware.opengl.extraPackages = flatten (map (vendor:
      if (vendor == "intel") then [
        pkgs.vaapiIntel	# Intel VA-API
        pkgs.libvdpau-va-gl	# the VDPAU driver with VA-API/OpenGL backend (e.g., for Adobe Flash Player and Mplayer; since there is no VDPAU available on Intel chips)
        pkgs.intel-ocl	# Official Intel OpenCL runtime
      ]
      else if (vendor == "nvidia") then [
        pkgs.vaapiVdpau	# HW video decode support in the VAAPI library for VDPAU platforms. e.g. NVIDIA
      ]
      else [ ]) cfg.hardware.chipsetVendors
    );
    virtualisation.virtualbox.guest = mkIf (any (vendor: vendor == "vbox") cfg.hardware.chipsetVendors) {
      enable = true;
    };

    nix.maxJobs = cfg.hardware.cpuCores;
    nix.buildCores = 0;
    zramSwap.numDevices = cfg.hardware.cpuCores;

    powerManagement.cpuFreqGovernor = mkIf (cfg.hardware.powersaving) (lib.mkDefault "powersave");
    services.tlp.enable = mkIf (cfg.hardware.powersaving) true;	# For optimal power management (better than pmutils)

    services.smartd.enable = cfg.hardware.smart;

    sound.enable = cfg.hardware.sound;

    networking.wireless = {
      enable = wifiEnabled;
      userControlled.enable = wifiWpaSupplicant;	# enabled only for wpa_supplicant to control it via wpa_cli/wpa_gui
      networks = { };	# if empty wpa_supplicant will use /etc/wpa_supplicant.conf as the configuration file, which is symlinked to the secure storage
    };
    networking.networkmanager.enable = wifiNetworkManager;
    environment.etc."wpa_supplicant.conf" = mkIf (wifiWpaSupplicant) {
      source = cfg.hardware.wifi;
    };

  } {

    ## boot

    boot = recursiveUpdateUntil (path: l: r: path == [ "loader" ]) {
      loader = {
        timeout = 1;
      } // optionalAttrs (cfg.boot.platform == "efi") {
        systemd-boot = {
          enable = true;
          editor = true;	# allow editing the kernel command-line before boot
        };
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";	# kernel and initramfs images will be in EFI directories
        };
      } // optionalAttrs (cfg.boot.platform == "bios") {
        grub = {
          enable = true;
          device = "/dev/sda";
          enableCryptodisk = true;
        };
      };
    } cfg.boot.extra;

  } {

    ## mount

    fileSystems = cfg.mount.fs;

    swapDevices = cfg.mount.swap;

    services.udisks2.enable = mkIf (cfg.mount.udisks != null) udisksEnabled;
    services.udev.extraRules = mkIf (udisksSetShare) ''
      # UDISKS_FILESYSTEM_SHARED
      # ==0: mount filesystem to a private directory (/run/media/$USER/VolumeName) which is on tmpfs
      # ==1: mount filesystem to a shared directory (/media/VolumeName) which should be on tmpfs
      # See udisks(8), https://wiki.archlinux.org/index.php/Udisks#Mount_to_.2Fmedia_.28udisks2.29
      ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="${if (cfg.mount.udisks == "user") then "0" else "1"}"
    '';

  } {

    ## printing

    services.printing.enable = printingEnabled;

    # CUPS web UI access
    services.printing.extraConf = mkIf (printingEnabled && (cfg.printing.webInterfaceUsers != [ ])) (mkAfter ''
      <Location />
        AuthType Basic
        Require user ${concatStringsSep " " cfg.printing.webInterfaceUsers}
      </Location>
    '');

    # CUPS drivers
    services.printing.drivers = mkAfter (builtins.getAttr "driver" (zipAttrsWithNames [ "driver" ] (name: values: values) cfg.printing.printers));

    # CUPS printers
    systemd.services.cups = mkIf (printingEnabled) {
      postStart = mkAfter (concatStringsSep "\n" (
        # remove all printers
        [ ''
          for I in $(lpstat -a | cut -d ' ' -f 1); do lpadmin -x "$I"; done
        '' ]
        ++
        # install defined printers
        map (printer:
          "lpadmin -p \"${printer.name}\" -m \"${printer.model}\" -v \"${printer.deviceUri}\""
          + optionalString (printer.info != null) " -D \"${printer.info}\""
          + optionalString (printer.location != null) " -L \"${printer.location}\""
          + concatMapStrings (option: " -o \"${option}\"") printer.options
          + " -E"
        ) cfg.printing.printers
        ++
        # set a default printer if any
        optional (cfg.printing.defaultPrinter != null) ''
          lpadmin -d "${cfg.printing.defaultPrinter}"
          echo "Default ${cfg.printing.defaultPrinter}" >/etc/cups/lpoptions
        ''
      ));
    };

    #
    assertions = [
      {
        assertion = (cfg.printing.defaultPrinter != null) -> (cfg.printing.printers != [ ]);
        message = "The default CUPS printer can be set only if CUPS printers are set.";
      }
    ];

  } {

    ## users

    users.users = builtins.listToAttrs (map (user: {
      inherit (user.nixOsUser) name;
      value = user.nixOsUser // {
        description = concatStringsSep "," ( [ ]
          ++ optional (user.fullName != null) (sanitizePasswdItem user.fullName)
          ++ optional (user.email != null) (sanitizePasswdItem user.email)
          ++ optional (user.key != null) (sanitizePasswdItem user.key)
          ++ optional ((builtins.hasAttr "description" user.nixOsUser) && (user.nixOsUser.description != null) && (user.nixOsUser.description != "")) user.nixOsUser.description
        );
        extraGroups = cfg.usersExtraGroups
          ++ optional ((builtins.hasAttr "extraGroups" user.nixOsUser) && (user.nixOsUser.extraGroups != null)) user.nixOsUser.extraGroups;
      };
    } ) (filter (user: user.addToUsersUsers) cfg.users));

    # web-browser Profile Sync Daemon will be activated for all users
    services.psd.users = map (user: user.nixOsUser.name) cfg.users;

    # auto-login
    services.mingetty.autologinUser = mkIf (cfg.mainUser.autoLoginMingetty) cfg.mainUser.name;
    services.xserver.displayManager = {
      auto = mkIf (cfg.mainUser.autoLoginXserver) {
        enable = mkDefault true;
        user = cfg.mainUser.name;
      };
      gdm.autoLogin = mkIf (cfg.mainUser.autoLoginXserver) {
        enable = true;
        user = cfg.mainUser.name;
      };
      lightdm.autoLogin = mkIf (cfg.mainUser.autoLoginXserver) {
        enable = true;
        user = cfg.mainUser.name;
      };
      sddm.autoLogin = mkIf (cfg.mainUser.autoLoginXserver) {
        enable = true;
        user = cfg.mainUser.name;
      };
      slim.autoLogin = mkIf (cfg.mainUser.autoLoginXserver) {
        enable = true;
        defaultUser = cfg.mainUser.name;
      };
    };

    # home-manager home.files and other configuration for individual users
    home-manager.users = builtins.listToAttrs (map (user: {
      inherit (user.nixOsUser) name;
      value = recursiveUpdateUntil (path: l: r: path == [ "home" "file" ]) {
        home.file =
          # global home files for all users individually
          (mapAttrs (name: value: value user) cfg.homeFiles)
          # the user's home files from its particular directory
          // optionalAttrs (user.homeFilesDirs != [ ]) (	# must use optionalAttrs, not mkIf which does not evaluate but just creates a conditional set
            targetSourceFilesFromDirs user.homeFilesDirs cfg.usersHomeFilesMatch.separator cfg.usersHomeFilesMatch.suffix
          );
      } (cfg.home-manager user);
    } ) cfg.users);

    #
    assertions = [
      {
        assertion = (cfg.mainUser.autoLoginMingetty || cfg.mainUser.autoLoginXserver) -> (cfg.mainUser.name != null);
        message = "Automatically logged in for a main user is enabled and the main user is not set.";
      }
      {
        assertion = builtins.all (user: (builtins.hasAttr "name" user.nixOsUser) && (builtins.hasAttr "home" user.nixOsUser)) cfg.users;
        message = "All users must have defined 'nixOsUser.name' and 'nixOsUser.home' attributes.";
      }
    ];

  } {

    ## gui

    # Wayland compositor Sway
    programs.sway = mkIf (cfg.gui.sway) {
      enable = true;
      extraPackages = with pkgs; [
        pkgs-custom.h2status
        xwayland
        rxvt_unicode-with-plugins	# otherwise there is a conflict of default rxvt_unicode extra package with the package set by services.urxvtd.enable
        rofi	# instead of default dmenu
      ];
      extraSessionCommands = ''
        export XKB_DEFAULT_LAYOUT=${config.services.xserver.layout}
        export XKB_DEFAULT_VARIANT=${config.services.xserver.xkbVariant}
        export XKB_DEFAULT_OPTIONS=${config.services.xserver.xkbOptions}
        export WLC_REPEAT_DELAY=${toString config.services.xserver.autoRepeatDelay}
        export WLC_REPEAT_RATE=${toString config.services.xserver.autoRepeatInterval}
        # use the native Wayland backend in Gtk+3
        export GDK_BACKEND="wayland"
        # use the native Wayland backend in Qt 5
        export QT_QPA_PLATFORM="wayland"
        #QT_QPA_PLATFORM="wayland-egl"
        # disable drawing client-side decorations for all windows in Qt
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        # run Clutter toolkit as a Wayland client
        export CLUTTER_BACKEND="wayland"
        # run SDL2 applications on Wayland
        export SDL_VIDEODRIVER="wayland"
        # dealloct all unsused virtual consoles as a previously terminated sway leaves its console in a graphical mode and it cannot be reused
        ${pkgs.kbd}/bin/deallocvt
      '';
    };

    # Enable the X11 windowing system
    services.xserver = mkIf (cfg.gui.xserver) {

      enable = true;
      autorun = true;
      exportConfiguration = true;

      # keyboard
      autoRepeatDelay = 300;
      autoRepeatInterval = 25;
      xkbOptions = "grp:alt_shift_toggle,grp_led:scroll,lv3:ralt_switch_multikey,altwin:meta_win";
      enableCtrlAltBackspace = true;

      # touchpad support
      libinput = {
        enable = true;
        accelSpeed = "0.25";
        clickMethod = "clickfinger";
        middleEmulation = false;
        tapping = false;
      };

      # display manager (GDM runs in Wayland by default services.xserver.displayManager.gdm.wayland and knows both X and Sway)
      displayManager = mkIf (cfg.gui.displayManager != null) {
        ${cfg.gui.displayManager}.enable = true;
        session = [
          {
            manage = "desktop";
            name = "urxvt";
            start = ''
              ${pkgs.rxvt_unicode-with-plugins}/bin/urxvt -ls &
              waitPID=$!
            '';
          }
        ];
      };

      # window manager
      windowManager = mkIf (cfg.gui.windowManager != null) {
        default = cfg.gui.windowManager;
        i3 = {
          enable = cfg.gui.windowManager == "i3";
          extraPackages = with pkgs; [
            rofi	# instead of default dmenu
            pkgs-custom.h2status
            i3lock
          ];
          # no configFile, as the configuration is in home-manager.users.*.services.xsession.windowManager.i3
        };
      };

      # desktop manager
      desktopManager = mkIf (cfg.gui.desktopManager != null) {
        default = cfg.gui.desktopManager;
        gnome3.enable = cfg.gui.desktopManager == "gnome3";
        lxqt.enable = cfg.gui.desktopManager == "lxqt";
        mate.enable = cfg.gui.desktopManager == "mate";
        plasma5.enable = cfg.gui.desktopManager == "plasma5";
        xfce.enable = cfg.gui.desktopManager == "xfce";
        # disable xterm, we have urxvt for window-managed environments above
        xterm.enable = false;
      };

    };

    # services with the window manager without any desktop manager
    systemd.user.services.kbdd = mkIf ((cfg.gui.windowManager != null) && (cfg.gui.desktopManager == null)) {	# pkgs.kbdd does not provide any systemd service
      description = "Keyboard library for per-window keyboard layout";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "ru.gentoo.KbddService";
        ExecStart = "${pkgs.kbdd}/bin/kbdd --nodaemon";
      };
    };

    #
    assertions = [
      {
        assertion = ((cfg.gui.displayManager != null) || (cfg.gui.windowManager != null) || (cfg.gui.desktopManager != null)) -> (cfg.gui.xserver == true);
        message = "Cannot use display-, window-, or desktop-managers without enabled X server.";	# FIX: can use gdm+sway without xserver
      }
    ];

  } ];

}
