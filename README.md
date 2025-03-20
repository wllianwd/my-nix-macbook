# Nix configuration for MacBook

A basic MacBook nix configuration.

## Installing Nix

Considering you aready download this repo and have it opened in your terminal:

```sh
# install nix
curl -sSf -L https://install.lix.systems/lix | sh -s -- install

# change global.nix accondingly to your information
nano global.nix

# build & apply nix (after that, you can close the terminal and open Alacritty)
nix run nix-darwin -- switch --flake . --show-trace
```

After the system is built from the first time, some additional commands will be available:
* `mnix`: open your Nix config directory
* `mnix-rebuild`: rebuild/apply your changes
* `mnix-update`: update packages + rebuild/apply your changes
* `mnix-develop`: will list all available shells defined inside `./shells`
* `oidea`: quick list/open IDEA project
* `oconfig`: quick list/open config repo
* `k`: for kubectl
* `z`: [zoxide](https://github.com/ajeetdsouza/zoxide) a smarter cd command
> You can check more in [./home/zsh/default.nix](./home/zsh/default.nix?ref_type=heads#L22)

Recommended apps:
* [zed](https://zed.dev/): text editor
* [ghostty](https://ghostty.org/): terminal
* [neovim](https://neovim.io/): terminal `$EDITOR`

### Configuring secrets

First step is to create a ssh key `id_nix` and store inside `./uncommited` (as we dont want to commit those keys to git).
> Remember to backup this key as you'll need it in a new computer to decrypt your secrets.
```sh
# open nix config directory
mnix

# create the key
ssh-keygen -t ed25519 -N "" -f ./uncommited/id_nix -q -C "<email>"
```
Now, we can use this key with [ragenix](https://github.com/yaxitech/ragenix) to encrypt and mount the files into our file system.

Each file will be encryted as a `<file>.age` and stored inside `home/agenix/secrets`.

Inside `home/ragenix/default.nix` we already have some files configured to be mounted in case exists inside `home/ragenix/secrets`, those are:
* If `home/ragenix/secrets/settings.xml.age` exists, it will mount inside `~/.m2/settings.xml`
* If `home/ragenix/secrets/id_rsa.age` exists, it will mount inside `~/.ssh/id_rsa`
* If `home/ragenix/secrets/id_rsa.pub.age` exists, it will mount inside `~/.ssh/id_rsa.pub`
* If `home/ragenix/secrets/id_github.age` exists, it will mount inside `~/.ssh/id_github`
* If `home/ragenix/secrets/id_github.pub.age` exists, it will mount inside `~/.ssh/id_github.pub`

For instance, considering you have all those files, you can encrypt into age files:
```sh
mnix-ragenix-create-secret -i /path_to_your_backup/settings.xml
mnix-ragenix-create-secret -i /path_to_your_backup/id_rsa
mnix-ragenix-create-secret -i /path_to_your_backup/id_rsa.pub
mnix-ragenix-create-secret -i /path_to_your_backup/id_github
mnix-ragenix-create-secret -i /path_to_your_backup/id_github.pub
```
You will be ble to see all files created under `home/ragenix/secrets`.

> You can follow the same approach for any other file, just update `home/ragenix/default.nix` accondingly.

### Docker

When building for the first time it will already install `docker`, `colima` and `docker-compose`.

### Managing Nix-Darwin Generations

#### List All Build Generations

To view all previous system generations, use one of the following commands:
```sh
darwin-rebuild list-generations
```
or

```sh
ls -l /nix/var/nix/profiles/
```
This will display the available system profiles and their respective generations.

#### Rollback to the Previous Generation
To revert to the last active generation, run:

```sh
darwin-rebuild switch --rollback
```

#### Rollback to a Specific Generation
To switch to a particular generation, use:

```sh
sudo /nix/var/nix/profiles/system-<generation>-link/activate
```
Replace <generation> with the desired generation number.
