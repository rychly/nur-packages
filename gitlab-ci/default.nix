# adopted from https://gitlab.com/Ma27/nur-packages/raw/master/gitlab-ci/default.nix

with import <nixpkgs> { config.checkMeta = true; };
callPackage ../. { }
