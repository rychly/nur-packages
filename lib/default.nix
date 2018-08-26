{ ... }:

rec {

  # Unstable/master version of nixpgs from its nix-channel or from its git repo if the channel is not available.
  # To add the channel use:
  # sudo nix-channel --add "http://nixos.org/channels/nixpkgs-unstable" nixpkgs-unstable
  # sudo nix-channel --update nixpkgs-unstable
  pkgs-unstable = let
    unstable-from-nix-channel = import <nixpkgs-unstable> { };
    unstable-from-git = builtins.fetchGit https://github.com/NixOS/nixpkgs.git;
  in with builtins.tryEval unstable-from-nix-channel; if success then value else unstable-from-git;

  # At least given version of given pkgs, that is the given version or an unstable/master version if the given pkgs is older.
  pkgs-in-version = given-pkgs: version:
    if (builtins.compareVersions (pkgs-version given-pkgs) version) >= 0
    then given-pkgs
    else pkgs-unstable;

  # Get a version of pkgs (`lib.nixpkgsVersion` for versions up to 18.03, `lib.version` for version 18.09 and later)
  pkgs-version = given-pkgs: if (builtins.hasAttr "version" given-pkgs.lib) then given-pkgs.lib.version else given-pkgs.lib.nixpkgsVersion;

}
