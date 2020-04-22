{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.gui;

  ## modules

  mainModuleOptions = {

    sway = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the tiling Wayland compositor Sway.";
    };

    xserver = mkOption {
      type = types.bool;
      default = (cfg.displayManager != null) || (cfg.windowManager != null) || (cfg.desktopManager != null);
      description = "Whether to enable the X server.";
    };

    displayManager = mkOption {
      type = types.nullOr (types.enum [ "auto" "gdm" "lightdm" "sddm" "xpra"]);
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

in {

  options.rychly.gui = mainModuleOptions;

  config = {

    # Wayland compositor Sway
    programs.sway = mkIf (cfg.sway) {
      enable = true;
      extraPackages = with pkgs; [
        h2status	# from rychly/nixpkgs-public
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
    services.xserver = mkIf (cfg.xserver) {

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

      displayManager.session = [
        {
          manage = "desktop";
          name = "urxvt";
          start = ''
            ${pkgs.rxvt_unicode-with-plugins}/bin/urxvt -ls &
            waitPID=$!
          '';
        }
      ];

      displayManager.${cfg.displayManager}.enable = (cfg.displayManager != null);

      # desktop and window manager

      desktopManager = {
        gnome3.enable = cfg.desktopManager == "gnome3";
        lxqt.enable = cfg.desktopManager == "lxqt";
        mate.enable = cfg.desktopManager == "mate";
        plasma5.enable = cfg.desktopManager == "plasma5";
        xfce.enable = cfg.desktopManager == "xfce";
        # disable xterm, we have urxvt for window-managed environments above
        xterm.enable = false;
      };

      windowManager.i3 = {
        enable = cfg.windowManager == "i3";
        extraPackages = with pkgs; [
          rofi	# instead of default dmenu
          h2status	# from rychly/nixpkgs-public
          i3lock
        ];
        # no configFile, as the configuration is in home-manager.users.*.services.xsession.windowManager.i3
      };

      displayManager.defaultSession =
        (if (cfg.desktopManager != null) then cfg.desktopManager else "none")
        + "+"
        + (if (cfg.windowManager != null) then cfg.windowManager else "none");

    };

    # services with the window manager without any desktop manager
    systemd.user.services.kbdd = mkIf ((cfg.windowManager != null) && (cfg.desktopManager == null)) {	# pkgs.kbdd does not provide any systemd service
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
        assertion = ((cfg.displayManager != null) || (cfg.windowManager != null) || (cfg.desktopManager != null)) -> (cfg.xserver == true);
        message = "Cannot use display-, window-, or desktop-managers without enabled X server.";	# FIX: can use gdm+sway without xserver
      }
    ];

  };

}
