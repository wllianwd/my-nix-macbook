{
  description = "Nix-darwin system flake";

  inputs = {
    # official nix packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # community driven nix packages
    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    # nix darwin
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # enable packages to be launch from spotlight or alfred
    mac-app-util.url = "github:hraban/mac-app-util";

    # agenix
    ragenix.url = "github:yaxitech/ragenix";
    ragenix.inputs.nixpkgs.follows = "nixpkgs";

    # nixvim
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      mac-app-util,
      ragenix,
      nvf,
      nur,
    }:
    let
      global = import ./global.nix;
      system = "aarch64-darwin"; # system architecture
      pkgs = import nixpkgs { inherit system; };

      # Base configuration now includes the user specific configuration.
      baseConfiguration =
        { pkgs, ... }:
        {
          # base system
          nix.settings.experimental-features = "nix-command flakes";
          nix.enable = false;
          system.primaryUser = global.username;
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 6;
          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.allowBroken = true;

          # enable touch id
          security.pam.services.sudo_local.touchIdAuth = true;
          security.pam.services.sudo_local.reattach = true;

          # defaults
          programs.zsh.enable = true;
          environment.systemPackages = [ pkgs.neovim ];
          system.defaults = {
            dock.autohide = true;
            dock.mru-spaces = false;
            finder.AppleShowAllExtensions = true;
            finder.FXPreferredViewStyle = "clmv";
            screencapture.location = "~/Pictures/screenshots";
            screensaver.askForPasswordDelay = 10;
          };

          # fonts
          fonts.packages = with pkgs; [
            pkgs.nerd-fonts.fira-code
            pkgs.nerd-fonts.droid-sans-mono
            pkgs.nerd-fonts.jetbrains-mono
            pkgs.nerd-fonts.meslo-lg
            pkgs.meslo-lgs-nf
          ];
        };

    in
    {
      darwinConfigurations."${global.host}" = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          {
            nixpkgs.overlays = [
              nur.overlays.default
            ];
          }
          baseConfiguration
          ./home/brew
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            # home-manager defaults
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
              ragenix.homeManagerModules.default
              nvf.homeManagerModules.default
            ];

            # home-manager specific
            users.users."${global.username}".home = "${global.homeDirectory}";
            home-manager.users."${global.username}" = import ./home;
          }
        ];
      };

      # expose devShells for easy access
      devShells.${system} = {
        python311 = import ./home/shells/python311.nix { inherit pkgs; };
        node22 = import ./home/shells/node22.nix { inherit pkgs; };
      };
    };
}
