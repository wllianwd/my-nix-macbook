{ pkgs, ... }:

let
  global = import ../global.nix;
in
{
  home.username = global.username;
  home.homeDirectory = "${global.homeDirectory}";

  imports = [
    ./ragenix
    ./ssh
    ./git
    ./zsh
    ./tmux
    ./ghostty
    ./nvf
    ./java
    ./zed
    ./idea
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    kubectl
    mob
    docker
    colima
    docker-compose
    ollama
    hoppscotch
    maven
    neofetch
    python3
    supabase-cli
    nodejs
    cargo
    rustc
    go
    redis
    openssl_3
    awscli2
    nixd
    nil
    alejandra
    nixfmt-rfc-style
    ragenix
    google-chrome
    slack
    zoom-us
    age
    ripgrep
    jq # A lightweight command-line JSON processor
    yq-go # yaml processor
    fzf # A command-line fuzzy finder
    fd
    cowsay
    which
    gawk
    obsidian # Note-taking app
    eza # Modern replacement of ls
    zoxide # Zoxide is a smarter cd command
    zip
    xz
    unzip
    p7zip
    gh # github ctl
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "24.11";

}
