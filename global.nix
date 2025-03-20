let
  # Just a description for your Mac
  host = "My-Macbook";

  # The username, should match with the /Users/<user>
  username = "<name>";

  # The user home directory
  homeDirectory = "/Users/${username}";

  # The place you are going to store this repo with your nix-config
  nixConfigDirectory = "${homeDirectory}/.my-nix-config";

  # The place you have your git repositories, will be used for some aliases like `oidea`
  repositoriesDirectory = "${homeDirectory}/Documents/repositories";

  # The git info
  gitEmail = "<email>";
  gitUserName = "<name>";

  # Temp dir used by darwin
  darwinUserTempDir = builtins.getEnv "TMPDIR";

in
{
  # Expose variables
  host = host;
  username = username;
  homeDirectory = homeDirectory;
  nixConfigDirectory = nixConfigDirectory;
  repositoriesDirectory = repositoriesDirectory;
  gitEmail = gitEmail;
  gitUserName = gitUserName;
  darwinUserTempDir = darwinUserTempDir;
}
