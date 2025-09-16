{
  description = "My public modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    lib = nixpkgs.lib // home-manager.lib;
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import nixpkgs {inherit system;};
            inherit system;
          }
      );
  in {
    devShells = let
      # TODO: use pipe-operator (|>)
      shellKeys = let
        allShells = builtins.attrNames (builtins.readDir ./shells);
        validShells = builtins.filter (name: lib.hasSuffix ".nix" name) allShells;
      in map (name: lib.removeSuffix ".nix" name) validShells;
      loadShells = args: lib.genAttrs shellKeys (name: import (./shells/${name}.nix) args);
    in forAllSystems ({ pkgs, system }: loadShells { inherit pkgs lib system; });

    formatter = forAllSystems ({pkgs, ...}:
      pkgs.writeShellScriptBin "alejandra" ''
        exec ${lib.getExe pkgs.alejandra} -qq **/*.nix "$@"
      '');

    nixosModules = {
      all = import ./modules/nixos;
    };

    homeManagerModules = {
      all = import ./modules/home;
    };
  };
}
