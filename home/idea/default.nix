{
  pkgs,
  lib,
  ...
}:
let
  fetchPluginSrc =
    { url, hash }:
    let
      isJar = lib.hasSuffix ".jar" url;
      fetcher = if isJar then pkgs.fetchurl else pkgs.fetchzip;
    in
    fetcher {
      executable = isJar;
      inherit url hash;
    };

  downloadPlugin =
    {
      name,
      version,
      url,
      hash,
      ... # Allow extra attributes from JSON if any, though not used here
    }:
    let
      isJar = lib.hasSuffix ".jar" url;
      installPhase =
        if isJar then
          ''
            runHook preInstall
            mkdir -p $out && cp $src $out
            runHook postInstall
          ''
        else
          ''
            runHook preInstall
            mkdir -p $out && cp -r . $out
            runHook postInstall
          '';
    in
    pkgs.stdenv.mkDerivation {
      inherit name version;
      src = fetchPluginSrc { inherit url hash; };
      dontUnpack = isJar;
      inherit installPhase;
    };

  # Read and parse the plugin list from the JSON file
  pluginDefinitions = builtins.fromJSON (builtins.readFile ./plugins.json);

  # Download all plugins defined in the JSON file
  downloadedPlugins = map downloadPlugin pluginDefinitions;

in
{
  home.packages = with pkgs; [
    (jetbrains.plugins.addPlugins jetbrains.idea-ultimate downloadedPlugins)
  ];

  home.file.".ideavimrc".text = builtins.readFile ./.ideavimrc;
}
