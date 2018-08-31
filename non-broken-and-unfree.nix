# This file filters out all the broken and unfree packages from your package set.
# It's what gets built by CI, so if you correctly mark broken and unfree packages as
# broken or unfree your CI will not try to build them and the non-broken and free packages will
# be added to the cache.
{ pkgs ? import <nixpkgs> {} }:

let filterSet =
      (f: g: s: builtins.listToAttrs
        (map
          (n: { name = n; value = builtins.getAttr n s; })
          (builtins.filter
            (n: f n && g (builtins.getAttr n s))
            (builtins.attrNames s)
          )
        )
      );
in filterSet
     (n: !(n=="lib"||n=="overlays"||n=="modules")) # filter out non-packages
     (p: (builtins.isAttrs p)
       && !(
             (builtins.hasAttr "meta" p)
             && (builtins.hasAttr "broken" p.meta)
             && (p.meta.broken)
           )
       && !(
             (builtins.hasAttr "meta" p)
             && (builtins.hasAttr "license" p.meta)
             && (
               ((builtins.isAttrs p.meta.license) && (builtins.hasAttr "free" p.meta.license) && (!p.meta.license.free))
               || ((builtins.isList p.meta.license) && (builtins.any (license: (builtins.hasAttr "free" license) && (!license.free)) p.meta.license))
             )
           )
     )
     (import ./default.nix { inherit pkgs; })
