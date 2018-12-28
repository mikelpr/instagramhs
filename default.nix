{ nixpkgs ? (import <nixpkgs> {}).pkgsMusl, compiler ? "ghc843", strip ? true }:
#{ nixpkgs ? (import <nixpkgs> {}).pkgsMusl, compiler ? "ghc863", strip ? true }:

let
  pkgs = nixpkgs.pkgsMusl;
  instagramhs = { mkDerivation, aeson, base, bytestring, directory, hpack, http-client-tls, http-conduit, stdenv, text }:
      mkDerivation {
        pname = "instagramhs";
        version = "0.0.1.0";
        src = pkgs.lib.sourceByRegex ./. [
          ".*\.cabal$"
          "^Setup.hs$"
          "^Main.hs$"
        ];
        isLibrary = false;
        isExecutable = true;
        enableSharedExecutables = false;
        enableSharedLibraries = false;
        executableHaskellDepends = [ aeson base bytestring directory http-client-tls http-conduit text ];
        license = stdenv.lib.licenses.gpl3Plus;
        configureFlags = [
          "--ghc-option=-optl=-static"
          "--extra-lib-dirs=${pkgs.gmp6.override { withStatic = true; }}/lib"
          "--extra-lib-dirs=${pkgs.zlib.static}/lib"
        ] ++ pkgs.lib.optionals (!strip) [
          "--disable-executable-stripping"
        ] ;
      };

  normalHaskellPackages = pkgs.haskell.packages.${compiler};
  haskellPackages = with pkgs.haskell.lib; normalHaskellPackages;
  
  drv = haskellPackages.callPackage instagramhs {};
in
  if pkgs.lib.inNixShell then drv.env else drv
