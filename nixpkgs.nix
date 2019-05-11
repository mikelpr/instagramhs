{ghcver? "ghc844"}:

let

  bootstrap = import <nixpkgs> {};

  nixpkgs-src = bootstrap.fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = "3fd87ad0073fd1ef71a8fcd1a1d1a89392c33d0a";
    sha256 = "0n4ffwwfdybphx1iyqz1p7npk8w4n78f8jr5nq8ldnx2amrkfwhl";
  };

  config = {
    allowUnfree = true;
    allowBroken = true;
    packageOverrides = pkgs: rec {
      haskell = pkgs.haskell // {
        packages = pkgs.haskell.packages // {
          ghc = pkgs.haskell.packages.${ghcver};
        };
      };
    };
  };

 in import nixpkgs-src {inherit config;}
