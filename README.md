# nur-packages

[![Pipeline status](https://gitlab.com/rychly/nur-packages/badges/master/pipeline.svg)](https://gitlab.com/rychly/nur-packages/commits/master)
[![Build Status](https://travis-ci.com/rychly/nur-packages.svg?branch=master)](https://travis-ci.com/rychly/nur-packages)
[![Coverage Report](https://gitlab.com/rychly/nur-packages/badges/master/coverage.svg)](https://gitlab.com/rychly/nur-packages/commits/master)
[![Cachix Cache](https://img.shields.io/badge/cachix-rychly-nur-packages-blue.svg)](https://rychly-nur-packages.cachix.org)

My own user-contributed packages as proposed in [nix-community/NUR](https://github.com/nix-community/nur).

## Setup

Import the `./nur-packages/nur` into the module arguments (it will be available as `nur` module function argument; also, all modules from `rychly` NUR repository will be imported) by:

``` nix
{ ... }:

{

  imports = [
    ./nur-packages/nur
  ];

}
```

You can also add and use NUR as [described in the docs](https://github.com/nix-community/nur#how-to-use).

## Usage

After the importing NUR as described above, the NUR repositories are available in modules via `nur` module function argument.
The `rychly` NUR repository is available locally and all other NUR repositories are fetched from the GIT NUR master branch.

### Packages

The packages available in this NUR repository can be installed like this:

``` nix
{ nur, ... }:

let

  pkgs-custom = nur.repos.rychly;

in {

  systemPackages = [
    pkgs-custom.<package-name>
  ];

}
```

### Overlays

There are several overlays available that can be imported with an expression like this:

``` nix
{ nur, ... }:

let

  overlays-custom = nur.repos.rychly.overlays;

in {

  nixpkgs.overlays = [
    overlays-custom.<overlay-name>
  ];

}
```

### Modules

After the importing NUR as described above, all modules from `rychly` NUR repository will be automatically imported.
