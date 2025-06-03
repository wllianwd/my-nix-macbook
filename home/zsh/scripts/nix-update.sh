#/bin/sh

echo "Executing: sudo nix flake update && sudo darwin-rebuild switch --flake ."

pushd $MY_NIX_CONFIG_DIR
sh ./home/zsh/scripts/nix-update-idea-plugins.sh
sudo nix flake update
sudo darwin-rebuild switch --flake .
popd
