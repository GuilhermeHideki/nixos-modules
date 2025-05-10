{
  config,
  lib,
  options,
  osConfig,
  pkgs,
  namespace,
  ...
}: {
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
  };
}
