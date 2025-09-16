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
