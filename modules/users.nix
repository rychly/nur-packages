{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.users;

  lib-custom = import ../lib { inherit lib; };

  ## modules

  userModule = types.submodule {

    options = {

      name = mkOption {
        type = types.str;
        description = "The username of the user (the same as in <code>config.users.users.<name>.name</code>."
          + " It must be defined also here to prevent infinite recursion by accessing <code>config.users.users</code>.";
      };

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
        description = "List of directories (by paths or strings; paths are stored in a public nix-store, strings are not stored and can be in a secure path ("
          + " (except for newer versions of home-manager, see https://github.com/rycee/home-manager/pull/541, use https://gitlab.com/rychly/home-manager/commit/6017a96afee8ba3d1fd6258b504c0d344d89beff)."
          + " The content of the directories will be symlinked to the home directory of the user by <code>home-manager.users.*.home.file</code>.";
      };

    };

  };

  mainModuleOptions = {

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
        default = lib-custom.hostNameFromName config.rychly.machine.name;
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

  };

  ## helpers

  # remove extra-item and intra-item separators from a password item
  sanitizePasswdItem = passwdItem: builtins.replaceStrings [ ":" "," ] [ "" "" ] passwdItem;

in {

  options.rychly.users = mainModuleOptions;

  config = {

    ## users

    users.users = builtins.listToAttrs (map (user: {
      inherit (user) name;
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
        user = mkDefault cfg.mainUser.name;
      };
      sddm.autoLogin = mkIf (cfg.mainUser.autoLoginXserver) {
        enable = true;
        user = cfg.mainUser.name;
      };
    };

    # home-manager home.files and other configuration for individual users
    home-manager.users = builtins.listToAttrs (map (user: {
      inherit (user) name;	# cannot access user.nixOsUser as (e.g., for "root") it results into infinite recursion because home-manager is trying to set users.users.<name>.packages (and maybe also for another reasons)
      value = recursiveUpdateUntil (path: l: r: path == [ "home" "file" ]) {
        home.file =
          # global home files for all users individually
          (mapAttrs (name: value: value user) cfg.homeFiles)
          # the user's home files from its particular directory
          // optionalAttrs (user.homeFilesDirs != [ ]) (	# must use optionalAttrs, not mkIf which does not evaluate but just creates a conditional set
            lib-custom.targetSourceFilesFromDirs user.homeFilesDirs cfg.usersHomeFilesMatch.separator cfg.usersHomeFilesMatch.suffix
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
        assertion = builtins.all (user: (builtins.hasAttr "name" user.nixOsUser) && (user.name == user.nixOsUser.name) && (builtins.hasAttr "home" user.nixOsUser)) cfg.users;
        message = "All users must have defined 'nixOsUser.name' (its value must be the same as a value of 'name' attribute of the user) and 'nixOsUser.home' attributes.";
      }
    ];

  };

}
