{ lib, ... }:

let
  fetchNixpkgsGit = ref: builtins.fetchGit {
    url = https://github.com/NixOS/nixpkgs.git;
    name = "nixpkgs-git-${ref}";
    inherit ref;
  };
in rec {

  # Unstable/master version of nixpgs from its nix-channel or from its git repo if the channel is not available.
  # To add the channel use:
  # sudo nix-channel --add "http://nixos.org/channels/nixpkgs-unstable" nixpkgs-unstable
  # sudo nix-channel --update nixpkgs-unstable
  pkgs-unstable = let
    unstable-from-nix-channel = import <nixpkgs-unstable> { };
    unstable-from-git = import (fetchGit "master");
  in with builtins.tryEval unstable-from-nix-channel; if success then value else unstable-from-git;

  # At least given version of given pkgs, that is the given version or an unstable/master version if the given pkgs is older.
  pkgs-in-version = given-pkgs: version:
    if (builtins.compareVersions (pkgs-version given-pkgs) version) >= 0
    then given-pkgs
    else pkgs-unstable;

  # Get a version of pkgs (`lib.nixpkgsVersion` for versions up to 18.03, `lib.version` for version 18.09 and later)
  pkgs-version = given-pkgs: if (builtins.hasAttr "version" given-pkgs.lib) then given-pkgs.lib.version else given-pkgs.lib.nixpkgsVersion;

  # Get fresh stable release from nixpkgs Git, that is the release beyond the staging stable release/channel
  pkgs-git-release = given-pkgs: let
    majorMinorVersion = given-pkgs.lib.versions.majorMinor given-pkgs.lib.version;
  in import (fetchNixpkgsGit "release-${majorMinorVersion}") { inherit (given-pkgs) config; };

  # create attrs for environment.etc or home-manager.users.*.home.file for all files in a given directory structure (optionaly, the resulting files will be based in a given path)
  targetSourceFilesFromDirs = dirs: suffixSeparator: suffix: let
    dirDeepFilesHierarchy = dir: base: lib.mapAttrsToList (name: value:
      let
        nameString = toString name;
        splitName = lib.splitString suffixSeparator nameString;
        isSuffixOk = ((builtins.tail splitName) == [ ]) || ((builtins.head (builtins.tail splitName)) == suffix);
        isIgnoredFile = (lib.substring 0 1 nameString == ".") || (lib.hasSuffix ".gpg" nameString) || (lib.hasSuffix ".example" nameString);
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
      pathWithoutInitialDot = lib.removePrefix "-" path;
    in if (pathWithoutInitialDot != path) then ".${pathWithoutInitialDot}" else path;
  in builtins.listToAttrs (map (pathPair: lib.nameValuePair (desanitizeFileName pathPair.target) { inherit (pathPair) source; }) (
    # skip empty sets generated by non-matching items
    builtins.filter (set: set != { }) (lib.flatten (map (dir: dirDeepFilesHierarchy dir ".") dirs)))
  );

  # split a name to its host name and domain parts
  parseNameToHostNameDomain = name: builtins.match "([^.]+)(.(.+))?" name;
  hostNameFromName = name: builtins.head (parseNameToHostNameDomain name);
  domainFromName = name: builtins.elemAt (parseNameToHostNameDomain name) 2;

}
