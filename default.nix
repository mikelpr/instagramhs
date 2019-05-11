{pkgs? import ./nixpkgs.nix {}}:
let
  inherit (pkgs.haskell.packages) ghc;
  drv = ghc.callCabal2nix "app" ./. {};
in
  if pkgs.lib.inNixShell then drv.env else drv
