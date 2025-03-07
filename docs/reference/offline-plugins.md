---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/offline-plugins.html
---

# Offline Plugin Management [offline-plugins]

The Logstash [plugin manager](/reference/working-with-plugins.md) provides support for preparing offline plugin packs that you can use to install Logstash plugins on systems that don’t have Internet access.

This procedure requires a staging machine running Logstash that has access to a public or [private Rubygems](/reference/private-rubygem.md) server. The staging machine downloads and packages all the files and dependencies required for offline installation.


## Building Offline Plugin Packs [building-offline-packs]

An *offline plugin pack* is a compressed file that contains all the plugins your offline Logstash installation requires, along with the dependencies for those plugins.

To build an offline plugin pack:

1. Make sure all the plugins that you want to package are installed on the staging server and that the staging server can access the Internet.
2. Run the `bin/logstash-plugin prepare-offline-pack` subcommand to package the plugins and dependencies:

    ```shell
    bin/logstash-plugin prepare-offline-pack --output OUTPUT --overwrite [PLUGINS]
    ```

    where:

    * `OUTPUT` specifies the zip file where the compressed plugin pack will be written. The default file is `/LOGSTASH_HOME/logstash-offline-plugins-9.0.0.zip`. If you are using 5.2.x and 5.3.0, this location should be a zip file whose contents will be overwritten.
    * `[PLUGINS]` specifies one or more plugins that you want to include in the pack.
    * `--overwrite` specifies if you want to override an existing file at the location


Examples:

```sh
bin/logstash-plugin prepare-offline-pack logstash-input-beats <1>
bin/logstash-plugin prepare-offline-pack logstash-filter-* <2>
bin/logstash-plugin prepare-offline-pack logstash-filter-* logstash-input-beats <3>
```

1. Packages the Beats input plugin and any dependencies.
2. Uses a wildcard to package all filter plugins and any dependencies.
3. Packages all filter plugins, the Beats input plugin, and any dependencies.


::::{note}
Downloading all dependencies for the specified plugins may take some time, depending on the plugins listed.
::::



## Installing Offline Plugin Packs [installing-offline-packs]

To install an offline plugin pack:

1. Move the compressed bundle to the machine where you want to install the plugins.
2. Run the `bin/logstash-plugin install` subcommand and pass in the file URI of the offline plugin pack.

    ```sh
    bin/logstash-plugin install file:///c:/path/to/logstash-offline-plugins-9.0.0.zip
    ```

    ```sh
    bin/logstash-plugin install file:///path/to/logstash-offline-plugins-9.0.0.zip
    ```

    This command expects a file URI, so make sure you use forward slashes and specify the full path to the pack.



## Updating Offline Plugins [updating-offline-packs]

To update offline plugins, you update the plugins on the staging server and then use the same process that you followed to build and install the plugin pack:

1. On the staging server, run the `bin/logstash-plugin update` subcommand to update the plugins. See [Updating plugins](/reference/working-with-plugins.md#updating-plugins).
2. Create a new version of the plugin pack. See [Building Offline Plugin Packs](#building-offline-packs).
3. Install the new version of the plugin pack. See [Installing Offline Plugin Packs](#installing-offline-packs).

