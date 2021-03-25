{ compiler? "ghc884"
, pkgs? (import ./nixpkgs.nix) }:

let inherit (pkgs.haskell.lib) overrideCabal;
    ghc = pkgs.haskell.packages.${compiler};
    drv = overrideCabal
            (import ./default.nix {pkgs=pkgs; compiler=compiler;})
            (old: {
              buildTools = old.buildTools ++ [
                ghc.cabal-install
                ghc.hoogle
                ghc.haskell-language-server
              ];
              # TODO hoogle hook
              # allowBroken = true;
            });

# avoid compiling program when invoking nix-shell for running hls
in if pkgs.lib.inNixShell then drv.env else drv
