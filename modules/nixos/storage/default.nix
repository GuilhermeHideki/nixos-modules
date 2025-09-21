{
  config,
  lib,
  namespace,
  username,
  ...
}: let
  cfg = config.${namespace}.storage;
in {
  imports = [
    ./btrfs-lvm-luks.nix
    ./btrfs-lvm.nix
    ./disko.nix
    ./mounts.nix
  ];

  options.${namespace}.storage = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    # Configuring permission so Home Manager works
    systemd.tmpfiles.rules = ["d /home/${username} 0750 ${username} ${username} -"];
  };
}
