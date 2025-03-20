{ config, lib, ... }:

let
  idRsaPath = "${config.home.homeDirectory}/.ssh/id_rsa";
  idGithubPath = "${config.home.homeDirectory}/.ssh/id_github";
  idRsaExists = builtins.pathExists ../ragenix/secrets/id_rsa.age;
  idGithubExists = builtins.pathExists ../ragenix/secrets/id_github.age;
in
{
  programs.ssh = {
    enable = true;
    matchBlocks = lib.filterAttrs (name: value: value != null) {
      "gitlab.my-company.com" = lib.mkIf idRsaExists {
        user = "git";
        identityFile = [ idRsaPath ];
      };
      "github.com" = lib.mkIf idGithubExists {
        user = "git";
        identityFile = [ idGithubPath ];
      };
    };
  };
}
