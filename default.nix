{ compiler? "ghc884"
, pkgs? (import ./nixpkgs.nix) }:

let inherit (pkgs.haskell.lib) overrideCabal;
    ghc = pkgs.haskell.packages.${compiler};
 in overrideCabal
      (ghc.callCabal2nix "app" ./. {})
      (old: {
        buildTools = [];
        doHaddock = false;
      })
