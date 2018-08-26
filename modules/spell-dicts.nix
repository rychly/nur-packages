{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.spellDicts;

in {

  options.rychly.spellDicts = {

    aspell = mkOption {
      type = types.nullOr types.unspecified;	# FIXME: the unspecified is lambda (ps: types.listOf types.package)
      default = null;
      description = "Function which will be called with <code>aspellDicts</code> as its single parameter and returns a list of attributes of this parameter representing enabled dictionaries.";
    };

    hunspell = mkOption {
      type = types.nullOr types.unspecified;	# FIXME: the unspecified is lambda (ps: types.listOf types.package)
      default = null;
      description = "Function which will be called with <code>hunspellDicts</code> as its single parameter and returns a list of attributes of this parameter representing enabled dictionaries.";
    };

  };

  # see https://github.com/NixOS/nixpkgs/issues/14430

  config = mkMerge [

    (mkIf (cfg.aspell != null) {

      # to use aspell with the particular dictionaries
      environment.systemPackages = [ (pkgs.aspellWithDicts cfg.aspell) ];

    })

    (mkIf (cfg.hunspell != null) {

      # to use hunspell with the particular dictionaries
      environment.systemPackages = [ (pkgs.hunspellWithDicts (cfg.hunspell pkgs.hunspellDicts)) ]
        # to use the standalone dictionaries in other aplications (only for hunspell; aspell dictionaties are already available in aspell-env)
        ++ (cfg.hunspell pkgs.hunspellDicts);

      # access /share/{hunspell,hyphen.mythes,myspell} where the dictionaries are
      environment.pathsToLink = [ "/share" ];

      # overrides the location of dictionary files in {pkgs.texworks} (it is a single directory, not a path varibale with comma separators)
      environment.variables.TW_DICPATH = "/run/current-system/sw/share/hunspell";

      # other hunspell applications, e.g., libreoffice
      environment.variables.DICPATH = "/run/current-system/sw/share/hunspell:/run/current-system/sw/share/hyphen:/run/current-system/sw/share/mythes";

    })

  ];

}
