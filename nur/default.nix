{ config, lib, pkgs, ... }:

let

  # the latest distribution NUR; see https://github.com/nix-community/NUR#installation
  nurLatest = import (builtins.fetchGit https://github.com/nix-community/NUR.git) {
    inherit pkgs;
  };

  # the local NUR repository
  nurLocal = {
    repos = {
      rychly = import ./.. {
        inherit pkgs;
      };
    };
  };

  # the distribution NUR with the local override
  nurWithLocalOverride = lib.recursiveUpdateUntil (path: l: r: path == [ "repos" ]) nurLatest nurLocal;

in {

  # import automatically all local modules

  imports = builtins.attrValues nurLocal.repos.rychly.modules;

  # add the following to function calls in all imported configurations (though the value will only be used in modules that directly refer to it)

  config._module.args.nur = nurWithLocalOverride;

  # add the following as attribute sub-set of the configuration attrbite set

  options.nur = with lib; mkOption {
    type = types.unspecified;	# its is read-only, so the type-check is not needed
    readOnly = true;
    description = "Read-only attribute set of the Nix User Repository (NUR) in its latest version with the local override.";
  };

  config.nur = nurWithLocalOverride;

}
