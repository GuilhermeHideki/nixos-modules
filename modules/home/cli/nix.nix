{
  config,
  lib,
  options,
  osConfig,
  pkgs,
  namespace,
  ...
}: let
  homeDir = builtins.toPath "/persist/${config.home.homeDirectory}";
  nixosRepo = builtins.toPath "${homeDir}/prj/gitlab.com/ghkd/nixos";
in {
  config = {
    ${namespace}.shell.aliases = {
      hms = "nh home switch $NIXOS_REPO";
      nup = "nh os switch $NIXOS_REPO";
      nupp = "nh os switch $NIXOS_REPO --update";
      nfu = "nix flake update";
    };

    home.packages = with pkgs; [
      nh
      devenv
    ];

    home.sessionVariables = {
      NIXOS_REPO = nixosRepo
    };
  };
}
