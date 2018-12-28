all:
	NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/2c07921cff84dfb0b9e0f6c2d10ee2bfee6a85ac.tar.gz nix-build --no-out-link
