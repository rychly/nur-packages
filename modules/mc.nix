{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.mc;

  ## modules

  extModule = types.submodule {

    options = {

      type = mkOption {
        type = types.enum [
          "shell"	# desc is, when starting with a dot, any extension (no wildcars), i.e. matches all the files *desc. Example: .tar matches *.tar; if it doesn't start with a dot, it matches only a file of that name
          "shell/i"	# desc is, when starting with a dot, any extension (no wildcars); The same as shell but with case insensitive.
          "regex"	# desc is an extended regular expression; Please note that we are using the GNU regex library and thus \| matches the literal | and | has special meaning (or) and () have special meaning and \( \) stand for literal ( ).
          "regex/i"	# desc is an extended regular expression; The same as regex but with case insensitive.
          "type"	# file matches this if `file %f` matches regular expression desc (the filename: part from `file %f` is removed)
          "type/i"	# file matches this if `file %f` matches regular expression desc; The same as type but with case insensitive.
          "directory"	# matches any directory matching regular expression desc
          "include"	# matches an include directive
          "default"	# matches any file no matter what desc is
        ];
        default = "default";
        description = "The first part of `keyword/descNL` section identifier.";
      };

      desc = mkOption {
        type = types.either types.str (types.listOf types.str);
        description = "The second part of `keyword/descNL` section identifier (it can be list to define the extension multiple-times).";
      };

      open = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Open action (if the user presses Enter or doubleclicks it).";
      };

      view = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "View action (F3).";
      };

      edit = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Edit action (F4).";
      };

      include = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "To add any further entries from an `include/` section.";
      };

      users = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "The list of usernames the extension should be applied (`null` for all usernames).";
      };

    };

  };

  mainModuleOptions = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure MC.";
    };

    exts = mkOption {
      type = types.listOf extModule;
      default = [ ];
      description = "Extension to provide view configuration and edit configuration beyond the default system-wide extensions file.";
    };

    mcPackage = mkOption {
      type = types.package;
      default = pkgs.mc;
      description = "The MC package where the default configuration files should be taken from.";
    };

  };

in {

  options.rychly.mc = mainModuleOptions;

  config = mkIf (cfg.enable) {

    environment.systemPackages = [ cfg.mcPackage ];

    rychly.users.homeFiles.".config/mc/mc.ext" = mkDefault (user: {
      text = let
        defaultExts = builtins.toPath "${cfg.mcPackage}/etc/mc/mc.ext";
      in
        (concatMapStrings (extCfg: if (builtins.isList extCfg.desc)
          then (concatMapStrings (desc:
            "${extCfg.type}/${desc}\n"
            + optionalString (extCfg.open != null) "\tOpen=${extCfg.open}\n"
            + optionalString (extCfg.view != null) "\tView=${extCfg.view}\n"
            + optionalString (extCfg.edit != null) "\tEdit=${extCfg.edit}\n"
            + optionalString (extCfg.include != null) "\tInclude=${extCfg.include}\n"
          ) extCfg.desc) else
            "${extCfg.type}/${extCfg.desc}\n"
            + optionalString (extCfg.open != null) "\tOpen=${extCfg.open}\n"
            + optionalString (extCfg.view != null) "\tView=${extCfg.view}\n"
            + optionalString (extCfg.edit != null) "\tEdit=${extCfg.edit}\n"
            + optionalString (extCfg.include != null) "\tInclude=${extCfg.include}\n"
        ) (builtins.filter (extCfg:
          (extCfg.users == null) || (builtins.elem user extCfg.users)
        ) cfg.exts))
        + "\n##### ${toString defaultExts}\n\n"
        + (builtins.readFile defaultExts);
    });

  };

}
