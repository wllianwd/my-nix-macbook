{ ... }:

let
  global = import ../../global.nix;
in
{

  programs.git = {
    enable = true;
    userName = global.gitUserName;
    userEmail = global.gitEmail;
  };

}
