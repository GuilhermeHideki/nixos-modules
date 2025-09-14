{
  config,
  lib,
  namespace,
  username,
  ...
}: let
  cfg = config.${namespace}.storage.mounts;
in {
  options.${namespace}.storage.mounts = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    # The big btrfs disk
    fileSystems."/storage/btrfs" = {
      device = "/dev/disk/by-uuid/d959c8dc-17d9-4d7e-baf1-42876ae2d061";
      options = ["nofail" "x-systemd.automount"];
    };

    # The 1 TB old disk
    fileSystems."/storage/download" = {
      device = "/dev/disk/by-uuid/44ba9123-0057-4cae-a550-372d5c3a7ae3";
      options = ["nofail" "x-systemd.automount"];
    };

    # 8 TB disk
    fileSystems."/storage/old/video" = {
      device = "/dev/disk/by-uuid/333b0783-9cfd-4268-8297-82653c6f9265";
      options = ["nofail" "x-systemd.automount"];
    };
  };
}
