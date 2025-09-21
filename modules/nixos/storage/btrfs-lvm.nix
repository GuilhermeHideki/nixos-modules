{
  config,
  lib,
  namespace,
  username,
  ...
}: let
  cfg = config.${namespace}.storage;
  mountOptions = cfg.lvm-btrfs.btrfsOptions;

  _mkSubvolume = {
    subvol,
    mountpoint,
    extra ? {},
  }: {
    "${subvol}" =
      {
        inherit mountOptions;
        extraArgs = ["-p"];
        mountpoint = builtins.toPath mountpoint;
      }
      // extra;
  };

  normalize = path: builtins.substring 1 (-1) path;

  mkSubvolume = path:
    _mkSubvolume {
      subvol = "@${normalize path}";
      mountpoint = "/${normalize path}";
    };

  withSnapshots = subvol: path:
    lib.mkMerge [
      (_mkSubvolume {
        inherit subvol;
        mountpoint = "${path}/.snapshots";
      })
      (_mkSubvolume {
        subvol = "${subvol}/live/snapshot";
        mountpoint = "${path}";
      })
    ];

  mkHomeSnapshot = user: withSnapshots "@home-${user}" "/home/${user}";
  mkSubvolumeWithSnapshots = path: withSnapshots "@${normalize path}" "/${normalize path}";

  mkNoDataCow = path: mountpoint: (_mkSubvolume {
    inherit mountpoint;
    subvol = "@${path}";
    extra = {
      mountOptions = mountOptions ++ ["nodatacow"];
    };
  });

  boot = size: {
    inherit size;
    name = "boot";
    type = "EF02";
  };

  esp = size: {
    label = "EFI";
    name = "ESP";
    size = lib.mkDefault size;
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/boot";
    };
  };

  lvm = size: {
    inherit size;
    content = {
      type = "lvm_pv";
      vg = "pool";
    };
  };
in {
  options.${namespace}.storage.lvm-btrfs = {
    enable = lib.mkEnableOption "";

    btrfsOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # TODO:: make ssd optional?
      default = ["defaults" "discard=async" "compress=zstd" "ssd" "noatime" "nodiratime"];
    };

    homes = lib.mkOption {
      description = "The home subvolumes";
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    noDataCow = lib.mkOption {
      description = "The subvolumes with nodatacow attribute";
      type = lib.types.attrsOf lib.types.str;
      default = {
        log = "/var/log";
        machines = "/var/lib/machines";
        portables = "/var/lib/portables";
      };
    };

    subvolumes = lib.mkOption {
      description = "The subvolumes without snapshots";
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    subvolumesWithSnapshots = lib.mkOption {
      description = "The subvolumes with snapshots";
      type = lib.types.listOf lib.types.str;
      default = [
        "/"
        "/persist"
      ];
    };
  };

  config = lib.mkIf cfg.lvm-btrfs.enable {
    virtualisation.vmVariantWithDisko = {
      disko.devices = {
        lvm_vg.pool.lvs.system.size = lib.mkForce "8G";
        lvm_vg.pool.lvs.swap.size = lib.mkForce "8G";
        disk.main.imageSize = "32G";
      };
    };

    disko.devices = {
      disk.main = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = boot "1M";
            esp = esp "512M";
            pool = lvm "100%";
          };
        };
      };
      lvm_vg.pool = {
        type = "lvm_vg";
        lvs = {
          main = {
            size = lib.mkDefault "100%FREE";
            content = let
              homes = cfg.lvm-btrfs.homes;
              subvolumes = lib.mkMerge (lib.lists.flatten ([
                  (map mkSubvolumeWithSnapshots cfg.lvm-btrfs.subvolumesWithSnapshots)
                  (map mkSubvolume cfg.lvm-btrfs.subvolumes)
                ]
                ++ (lib.lists.optionals (builtins.length homes != 0)) [
                  (map mkSubvolume ["/home"])
                  (map mkHomeSnapshot homes)
                ]));
            in {
              type = "btrfs";
              inherit subvolumes;

              postCreateHook = let
                forEach = values: f: lib.strings.concatStringsSep "\n" (map (v: f v) values);
                subvolumeWithSnapshot = let
                  filter = _: v: v ? "" && lib.hasSuffix "/.snapshot" v.mountpoint;
                  snapshots = builtins.attrValues (lib.attrsets.filterAttrs filter subvolumes);
                in
                  map (v: v.mountpoint) snapshots;
              in ''
                MNTPOINT=$(mktemp -d)

                mount "/dev/pool/main" "$MNTPOINT" -o subvol=/
                trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT

                # ls -lahR $MNTPOINT
                # btrfs subvolume list $MNTPOINT
                # cd $MNTPOINT

                ${forEach subvolumeWithSnapshot (subvol: ''
                  mkdir -p "$MNTPOINT/${subvol}/blank/snapshot"
                '')}

                ${forEach subvolumeWithSnapshot (subvol: ''
                  btrfs subvolume snapshot -r "$MNTPOINT/${subvol}/live/snapshot" "$MNTPOINT/${subvol}/blank/snapshot"
                '')}
              '';
            };
          };
          system = {
            size = lib.mkDefault "100G";
            content.type = "btrfs";
            content.subvolumes = lib.mkMerge (lib.mapAttrsToList mkNoDataCow cfg.lvm-btrfs.noDataCow);
          };
          swap = {
            size = lib.mkDefault "32G";
            content.type = "swap";
          };
        };
      };
    };
  };
}
