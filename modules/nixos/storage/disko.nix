{
  config,
  lib,
  namespace,
  username,
  ...
}: let
  cfg = config.${namespace}.storage;

  fileSystems = {
    # /etc/ssh keys to sshd and sops-nix
    "/persist".neededForBoot = true;
    # /nix
    "/".neededForBoot = true;
  };
in {
  options.${namespace}.storage.persist = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.persist.enable {
    # Persist paths (/persist and /nix)
    inherit fileSystems;

    disko.tests.extraConfig = {
      virtualisation = {
        inherit fileSystems;
      };
      users.users.${username} = {
        hashedPasswordFile = lib.mkForce null;
        password = username;
      };
    };
  };
}
