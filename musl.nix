{ pkgs? ((import ./nixpkgs.nix).pkgsMusl)
, compiler ? "ghc884"
, strip ? true }:

let
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
  
  drv = with pkgs.haskell.lib; pkgs.haskell.packages.${compiler}.callPackage instagramhs {};
in
  if pkgs.lib.inNixShell then drv.env else drv
