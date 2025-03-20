{ pkgs, ... }:
let
  global = import ../../global.nix;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    sessionVariables = {
      MY_NIX_CONFIG_DIR = global.nixConfigDirectory;
      PATH = "$HOME/.nix-profile/bin:/opt/homebrew/bin:$PATH";
      EDITOR = "nvim";
      DOCKER_HOST = "unix://$HOME/.colima/default/docker.sock";
      TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
      TESTCONTAINERS_HOST_OVERRIDE = "colima ls -j | jq -r '.address'";
    };

    shellAliases = {
      ll = "eza -l";
      ls = "eza -la";
      k = "kubectl";
      kgp = "kubectl get pods";
      kgd = "kubectl get deployments";
      kl = "kubectl logs -f";
      oidea = "fd . '${global.repositoriesDirectory}' --type d --hidden --exclude .git --max-depth 1 | fzf | xargs -I {} idea {}";
      orepositories = "cd ${global.repositoriesDirectory}";
      oconfigs = "cd ${global.repositoriesDirectory}/configs";
      oconfig = "fd . '${global.repositoriesDirectory}/configs' --type d --hidden --exclude .git --max-depth 1 | fzf | xargs -I {} nvim {}";
      mnix = "cd ${global.nixConfigDirectory}";
      mnix-rebuild = "sh ${global.nixConfigDirectory}/home/zsh/scripts/nix-rebuild.sh";
      mnix-update = "sh ${global.nixConfigDirectory}/home/zsh/scripts/nix-update.sh";
      mnix-develop = "nix develop ${global.nixConfigDirectory}#$(fd . '${global.nixConfigDirectory}/shells' --type f --hidden --exclude '*.md' --max-depth 1 | xargs -I {} basename {} .nix | fzf)";
      mnix-ragenix-create-secret = "sh ${global.nixConfigDirectory}/home/zsh/scripts/ragenix-create-secret.sh";
    };

    history = {
      size = 10000;
    };

    plugins = [
      # Config with: POWERLEVEL9K_CONFIG_FILE=$MY_NIX_CONFIG_DIR/home/zsh/p10k-config/p10k.zsh p10k configure
      {
        name = "powerlevel10k-config";
        src = ./p10k-config;
        file = "p10k.zsh";
      }
      {
        name = "zsh-powerlevel10k";
        src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
        file = "powerlevel10k.zsh-theme";
      }
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [
        "docker-compose"
        "docker"
        "git"
      ];
    };

    initExtra = ''
      # tmux to have correct color setting
      if [ ! "$TMUX" = "" ]; then
        export TERM=xterm-256color;
      fi

      # configure zoxide
      eval "$(zoxide init zsh)"
    '';
  };
}
