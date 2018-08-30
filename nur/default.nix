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

  # use the distribution NUR with the local override
  nurWithLocalOverride = nurLatest // {
    repos = nurLatest.repos // nurLocal.repos;
  };

in {

  # import automatically all local modules

  imports = builtins.attrValues nurLocal.repos.rychly.modules;

  # add the following as attribute sub-set of the configuration attrbite set

  options.nur = with lib; mkOption {
    type = types.unspecified;	# its is read-only, so the type-check is not needed
    readOnly = true;
    description = "Read-only attribute set of the global Nix User Repository (NUR) in its latest version with the local override.";
  };

  options.nurLocal = with lib; mkOption {
    type = types.unspecified;	# its is read-only, so the type-check is not needed
    readOnly = true;
    description = "Read-only attribute set of the local Nix User Repository (NUR).";
  };

  config.nur = nurWithLocalOverride;
  config.nurLocal = nurLocal;

  # Do not use `config._module.args.nur` to add the NUR to function calls in all imported configurations (though the value will only be used in modules that directly refer to it).
  # * setting config._module here and its usage otherwhere may result into "inifinite recursion" (it is better to use `config.nur` as defined above)
  # * _module.args are evaulated first even before they are utilised (and that is also reason for the "inifinite recursion")

}
