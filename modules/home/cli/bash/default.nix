{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: {
  programs.bash = {
    enable = true;
    shellAliases = config.${namespace}.shell.aliases;
  };
}
