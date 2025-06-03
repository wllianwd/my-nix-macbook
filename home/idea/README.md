# IDEA

## Plugins

All plugins are configured inside `plugins.json`.

In case you want to add a new plugin, you just need the plugin id. You can search via [website](https://plugins.jetbrains.com/) or via IDEA UI > Go to homepage and get the plugin id from the URL.

For instance, [kafka](https://plugins.jetbrains.com/plugin/21704-kafka) plugin id is `21704`, so you can add an entry inside `plugins.json` with the `id` and an empty `version`:
```
[
  // existing plugins
  {
    "id": 1,
    "version": "0.0.1",
    "url": "https://jetbrains....",
    "hash": "sha256-...."
  },
  ...
  // new plugin
  {
    "id": 21704,
    "version": ""
  }
]
```
```
# Update system, including handling new IDEA plugins added in the `plugins.json`
mnix-update

# If you want to update just the `plugins.json` and rebuild the current system (without updating the entire system)
sh $MY_NIX_CONFIG_DIR/home/zsh/scripts/nix-update-idea-plugins.sh
mnix-rebuild
```
You will see the bellow log and the `plugins.json` will be updated automatically:
```
--------------------------------------------------
[INFO] Plugin updates to be applied automatically:
  - Plugin: 'Kafka' (ID: 21704) ==> New Version: '252.16512.17'
--------------------------------------------------
```
