{
  config,
  namespace,
  lib,
  ...
}: {
  imports = [
    ./git.nix
    ./tools.nix
  ];

  options.${namespace} = {
    shell.aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
    };
  };

  config.xdg = {
    enable = true;
    userDirs.music = "${config.home.homeDirectory}/music";
    userDirs.download = "${config.home.homeDirectory}/downloads";
  };
}
