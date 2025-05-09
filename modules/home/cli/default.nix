{
  config,
}: {
  config.xdg = {
    enable = true;
    userDirs.music = "${config.home.homeDirectory}/music";
    userDirs.download = "${config.home.homeDirectory}/downloads";
  };
}
