#/bin/sh

echo "Executing: sudo darwin-rebuild switch --flake ."

pushd $MY_NIX_CONFIG_DIR
sudo darwin-rebuild switch --flake .
popd
