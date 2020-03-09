# nur-packages

[![Pipeline status](https://gitlab.com/rychly/nur-packages/badges/master/pipeline.svg)](https://gitlab.com/rychly/nur-packages/commits/master)
[![Build Status](https://travis-ci.org/rychly/nur-packages.svg?branch=master)](https://travis-ci.org/rychly/nur-packages)
[![Coverage Report](https://gitlab.com/rychly/nur-packages/badges/master/coverage.svg)](https://gitlab.com/rychly/nur-packages/commits/master)
[![Cachix Cache](https://img.shields.io/badge/cachix-rychly-nur-packages-blue.svg)](https://rychly-nur-packages.cachix.org)

My own user-contributed packages as proposed in [nix-community/NUR](https://github.com/nix-community/nur).

## Setup

By importing `./nur-packages/nur`, the NUR will be available as:

* `config.nur` option for the global NUR with the local override (it is safe to use if online)
* `config.nurLocal` option for the local NUR only (it is safe to use if offline)

In the first case, the `rychly` NUR repository is available locally and all other NUR repositories are fetched from the GIT NUR master branch.
Also, all modules from the `rychly` NUR repository will be imported automatically.

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

After the importing NUR as described above, the NUR is available in modules via `config.nur` and `config.nurLocal` options.

### Overlays

There are several overlays available that can be imported with an expression like this:

``` nix
{ config, ... }:

let

  overlays-custom = config.nurLocal.repos.rychly.overlays;

in {

  nixpkgs.overlays = [
    overlays-custom.<overlay-name>
  ];

}
```

### Modules

After the importing NUR as described above, all modules from `rychly` NUR repository will be imported automatically.
