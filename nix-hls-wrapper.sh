#!/bin/sh
NIXPKGS_ALLOW_UNFREE=1 nix-shell --pure hls.nix --run "haskell-language-server $@"
