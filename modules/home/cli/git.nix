{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  homeDir = builtins.toPath "/persist/${config.home.homeDirectory}";
  cfg = config.${namespace}.git;
in {
  options.${namespace}.git = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.shell.aliases = {
      g = "git";
    };

    programs.git = {
      enable = lib.mkDefault true;
      package = pkgs.gitMinimal;

      includes = [
        {path = "~/.config/git/.gitconfig";}
      ];

      delta.enable = true;

      aliases = {
        alias = "!git config -l | grep ^alias | cut -c 7- | sort";
        aliases = "config --get-regexp alias";

        remotes = "remote -v";
        stashes = "stash list";
        tags = "tag -l";

        # List contributors with number of commits
        contributors = "shortlog --summary --numbered";

        # Credit an author on the latest commit
        credit = "!f() { git commit --amend --author \"$1 <$2>\" -C HEAD; }; f";

        br = "branch";
        branches = "branch -a";

        # TODO: use an env var to change the "protected branches"
        brd = "!f() { git branch --merged | grep -Ev '^[*]|main' | xargs -r git branch -d; }; f";

        cd = "checkout";
        cm = "commit";

        # Amend the currently staged files to the latest commit
        amend = "commit --amend --reuse-message=HEAD";
        discard = "checkout --";
        uncommit = "reset --mixed HEAD~";
        unstage = "reset -q HEAD --";
        untrack = "rm -r --cached";

        d = "diff";
        dc = "diff --cached";

        lg = "log --color --decorate --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an (%G?)>%Creset' --abbrev-commit";
        tree = "log --graph --decorate --pretty=oneline --abbrev-commit";
        graph = "log --graph --color --pretty=format:%C(yellow)%H%C(green)%d%C(reset)%n%x20%cd%n%x20%cn%x20(%ce)%n%x20%s%n";

        pl = "pull --all --prune";
        ps = "push";
        psf = "push --force-with-lease";

        # Interactive rebase with the given number of latest commits
        reb = "!r() { git rebase -i HEAD~$1; }; r";
        rbc = "rebase --continue";

        s = "status -s";
        st = "status";
      };

      lfs.enable = true;

      extraConfig = {
        color.ui = "auto";

        advice.skippedCherryPicks = false;

        apply.whitespace = "fix";

        # branch.autosetupmerge = "always";
        branch.autosetuprebase = "always";

        help.autocorrect = "10";

        init.defaultBranch = "main";
        core.excludesFile = "~/.config/git/ignore";
        core.quotePath = "off";
        core.editor = "nvim";

        pull.ff = "only";
        push.default = "current";
        push.autoSetupRemote = "true";
        rebase.autosquash = "true";
        rerere.enabled = "true";

        # Use ssh by default (github)
        url."git@github.com:".insteadOf = [
          "git://github.com/"
          "http://github.com/"
          "https://github.com/"
        ];

        # Use ssh by default (gitlab)
        url."git@gitlab.com:".insteadOf = [
          "http://gitlab.com/"
          "https://gitlab.com/"
          "git://gitlab.com/"
        ];
      };
    };

    home.packages = with pkgs; [
      hub
      delta # diffs

      # Helper to make API calls to GitLab API
      (writeShellApplication {
        name = "gitlab";
        runtimeInputs = [httpie];
        text = ''
          https "$@" "Authorization:Bearer $GITLAB_TOKEN"
        '';
      })

      # Workaround to use multiple tokens / "profiles"
      (writeShellApplication {
        name = "lab";
        runtimeInputs = [lab];
        text = ''
          LAB_CORE_HOST="https://gitlab.com" \
          LAB_CORE_TOKEN=$GITLAB_TOKEN \
          ${pkgs.lab}/bin/lab "$@"
        '';
      })

      # Gitlab Helper to get the repo URL and click from terminal
      (writeShellApplication {
        name = "git-url";
        runtimeInputs = [
          git
          sd
        ];
        text = ''
          # shellcheck disable=SC2016
          git remote get-url "''${1-origin}" | \
            sd 'git@(?:[\w.]+\.)?((?:[\w]+.){2}):(.+)' 'https://$1/$2'
        '';
      })
    ];

    home.file.".config/lab/lab.toml".text = ''
      [mr_create]
        draft = false
    '';
  };
}
