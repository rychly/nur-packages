{ pkgs ? import <nixpkgs> { }
, lib-custom ? import ../lib { }
, pkgs-custom ? import ../pkgs { inherit pkgs; }
}:

{

  busyboxBinaryOnly = self: super: {
    # busybox binary without symlinks to its applets as the symlinks may break the system, see https://github.com/NixOS/nixpkgs/issues/10716
    busyboxBinaryOnly = super.busybox.override {
      extraConfig = ''
        CONFIG_INSTALL_APPLET_DONT y
        CONFIG_INSTALL_APPLET_SYMLINKS n
      '';
    };
  };

  dunstify = self: super: {
    # dunst with dunstify is only in the unstable, that is after r18.03, see https://github.com/NixOS/nixpkgs/commit/6df7a8b34cf2aad6affd1838af18c4900be4dd18
    dunst = (lib-custom.pkgs-in-version super "18.09").dunst.override {
      dunstify = true;
    };
  };

  chmlibWithExamples = self: super: {
    # Build example programs that use chmlib
    chmlibWithExamples = super.chmlib.overrideAttrs(oldAttrs: rec {
      configureFlags = [
        # from Gentoo, see https://github.com/gentoo/gentoo/blob/master/dev-libs/chmlib/chmlib-0.40-r1.ebuild#L24
        "--enable-examples"
      ];
    });
  };

  jetbrainsWithSystemJdk = self: super: let
    systemJdk = { jdk = super.jdk; };
  in {
    # jetbrains.* packages require jetbrains.jdk which is available only for x64, see https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/compilers/jetbrains-jdk/default.nix#L13
    # fix: switched to the system JDK by reversing https://github.com/NixOS/nixpkgs/issues/23115
    jetbrains.datagrip = super.jetbrains.datagrip.override systemJdk;
    jetbrains.idea-ultimate = super.jetbrains.idea-ultimate.override systemJdk;
    jetbrains.pycharm-professional = super.jetbrains.pycharm-professional.override systemJdk;
  };

  libreofficeWithCsLang = self: super: let
    libreoffice-langs = super-libreoffice: langs: super-libreoffice.override {
      libreoffice = super-libreoffice.libreoffice.override { inherit langs; };
    };
  in {
    # LibreOffice language-specific build, libreoffice building is quite exhaustive
    libreoffice-still = libreoffice-langs super.libreoffice-still [ "en-US" "cs" ];
  };

  mkdocsWithMyPlugins = self: super: {
    mkdocs-with-plugins = pkgs-custom.mkdocs-with-plugins.override {
      plugins = (ps: with ps; [ pkgs-custom.mkdocs-material ]);
    };
  };

  modelioWithAllPlugins = self: super: {
    # Modelio plugins
    modelio36 = pkgs-custom.modelio36.override {
      plugins = [
        pkgs-custom.modelio-plugin-ba36
        pkgs-custom.modelio-plugin-sa36
        pkgs-custom.modelio-plugin-sd36
      ];
    };
    modelio37 = pkgs-custom.modelio37.override {
      plugins = [
        pkgs-custom.modelio-plugin-ba37
        pkgs-custom.modelio-plugin-sa37
        pkgs-custom.modelio-plugin-sd37
      ];
    };
    modelio38 = pkgs-custom.modelio38.override {
      plugins = [
        pkgs-custom.modelio-plugin-ba38
        pkgs-custom.modelio-plugin-sa38
        pkgs-custom.modelio-plugin-sd38
      ];
    };
  };

  openldapMinimal = self: super: {
    # minimal LDAP (just a client); cannot override as "openldap" as it would cause massive rebuilds of dependents, e.g., libreoffice, etc.
    openldap-minimal = super.openldap.overrideAttrs(oldAttrs: rec {
      configureFlags = oldAttrs.configureFlags ++ [
        # from Gentoo, see https://github.com/gentoo/gentoo/blob/master/net-nds/openldap/openldap-2.4.45.ebuild#L465
        "--disable-backends" "--disable-slapd" "--disable-bdb" "--disable-hdb" "--disable-mdb" "--disable-overlays" "--disable-syslog"
      ];
    });
  };

  pidginWithMyPlugins = self: super: {
    # Pidgin plugins, see https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/networking/instant-messengers/pidgin-plugins
    pidgin-with-plugins = super.pidgin-with-plugins.override {
      plugins = [
        super.pidgin-sipe
        super.pidgin-window-merge
        super.pidgin-xmpp-receipts
        super.purple-hangouts
      ];
    };
  };

  rofiWithGlueProBlueTheme = self: super: {
    # rofi theme is possible to set only in the unstable, that is after r18.03, see https://github.com/NixOS/nixpkgs/commits/master/pkgs/applications/misc/rofi/wrapper.nix
    rofi = let
      super-rofi = (lib-custom.pkgs-in-version super "18.09").rofi;
    in super-rofi.override {
      theme = "${super-rofi}/share/rofi/themes/glue_pro_blue";
    };
  };

  virtualboxWithExtensionPack = self: super: {
    # VirtualBox with Extension Pack (unfree are not built on hydra, so the overriding causes a recompilation, there can be with errors)
    # extpack cannot be added by different means, e.g., by symlinkJoin/cp due to hardening (runtime error: Internal executable does reside under RTPathAppPrivateArch)
    # FIXME: compilation fails, waiting for better solution, see https://github.com/NixOS/nixpkgs/issues/34796#issuecomment-406095992
    virtualbox = super.virtualbox.override {
      enableExtensionPack = true;
    };
  };

  versionUpdates = self: super: {
    # FIXME: automatically check if the pkgs-custom versions are newer than pkgs versions
    adbfs-rootless = pkgs-custom.adbfs-rootless;
  };

  freshRelease = self: super: {
    # fresh stable release packages beyond the staging stable release/channel
    jetbrains = (lib-custom.pkgs-git-release super).jetbrains;
  };

}
