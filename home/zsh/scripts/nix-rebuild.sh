#/bin/sh

echo "Executing: nix run nix-darwin -- switch --flake . --show-trace"

pushd $MY_NIX_CONFIG_DIR
nix run nix-darwin -- switch --flake . --show-trace
popd
