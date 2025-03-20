#/bin/sh

echo "Executing: nix flake update && nix run nix-darwin -- switch --flake . --show-trace"

pushd $MY_NIX_CONFIG_DIR
nix flake update
nix run nix-darwin -- switch --flake . --show-trace
popd
