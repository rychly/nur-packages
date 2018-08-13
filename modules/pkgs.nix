{ lib, pkgs, ... }:

with lib;

{

  options.custom.pkgs = mkOption {
    type = types.attrsOf (types.either types.package (types.attrsOf types.package));	# set of: packages or sets of packages
    readOnly = true;
    description = "Read-only set of custom packages.";
  };

  config = {

    custom.pkgs = import ./.. { inherit pkgs; };

  };

}
