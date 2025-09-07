{
  config,
  lib,
  options,
  osConfig,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.${namespace};
in {
  options.${namespace} = {
    projectRoots = lib.mkOption {
      description = ''
        Where should I search for projects
      '';
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = {
    ${namespace}.shell.aliases = {
      hms = "nh home switch $NIXOS_REPO";
      nup = "nh os switch $NIXOS_REPO";
      nupp = "nh os switch $NIXOS_REPO --update";
      nfu = "nix flake update";
    };

    home.homeDirectory = "/home/${config.home.username}";

    home.sessionVariables = {
      PROJECT_ROOTS = lib.strings.concatStringsSep ":" cfg.projectRoots;
    };

    home.packages = with pkgs; [
      nh
      devenv
    ];
  };
}
