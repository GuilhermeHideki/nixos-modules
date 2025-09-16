{
  pkgs,
  lib,
  system,
}:
pkgs.mkShell {
  shellHook = ''
    printf "We have these commands defined\n\n"
    runme list --allow-unnamed
  '';
  packages = with pkgs; [
    runme
  ];
}
