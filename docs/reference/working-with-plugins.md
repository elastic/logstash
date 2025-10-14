---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/working-with-plugins.html
---

# Working with plugins [working-with-plugins]

::::{admonition} macOS Gatekeeper warnings
:class: important

Apple’s rollout of stricter notarization requirements affected the notarization of the {{version.stack}} {{ls}} artifacts. If macOS Catalina displays a dialog when you first run {{ls}}, you need to take an action to allow it to run. To prevent Gatekeeper checks on the {{ls}} files, run the following command on the downloaded `.tar.gz` archive or the directory to which was extracted:

```sh
xattr -d -r com.apple.quarantine <archive-or-directory>
```

For example, if the `.tar.gz` file was extracted to the default logstash-{{version.stack}} directory, the command is:

```sh subs=true
xattr -d -r com.apple.quarantine logstash-{{version.stack}}
```

Alternatively, you can add a security override if a Gatekeeper popup appears by following the instructions in the *How to open an app that hasn’t been notarized or is from an unidentified developer* section of [Safely open apps on your Mac](https://support.apple.com/en-us/HT202491).

::::


Logstash has a rich collection of input, filter, codec, and output plugins. Check out the [Elastic Support Matrix](https://www.elastic.co/support/matrix#matrix_logstash_plugins) to see which plugins are supported at various levels.

Plugins are available in self-contained packages called gems and hosted on [RubyGems.org](https://rubygems.org/). Use the plugin manager script--`bin/logstash-plugin`--to manage plugins:

* [Listing plugins](#listing-plugins)
* [Adding plugins to your deployment](#installing-plugins)
* [Updating plugins](#updating-plugins)
* [Removing plugins](#removing-plugins)
* [Advanced: Adding a locally built plugin](#installing-local-plugins)
* [Advanced: Using `--path.plugins`](#installing-local-plugins-path)


## No internet connection? [pointer-to-offline]

If you don’t have an internet connection, check out [Offline Plugin Management](/reference/offline-plugins.md) for information on [building](/reference/offline-plugins.md#building-offline-packs), [installing](/reference/offline-plugins.md#installing-offline-packs), and [updating](/reference/offline-plugins.md#updating-offline-packs) offline plugin packs.


### Proxy configuration [http-proxy]

Most plugin manager commands require access to the internet to reach [RubyGems.org](https://rubygems.org). If your organization is behind a firewall, you can set these environments variables to configure Logstash to use your proxy.

```shell
export http_proxy=http://localhost:3128
export https_proxy=http://localhost:3128
```


## Listing plugins [listing-plugins]

Logstash release packages bundle common plugins. To list the plugins currently available in your deployment:

```shell
bin/logstash-plugin list <1>
bin/logstash-plugin list --verbose <2>
bin/logstash-plugin list '*namefragment*' <3>
bin/logstash-plugin list --group output <4>
```

1. Lists all installed plugins
2. Lists installed plugins with version information
3. Lists all installed plugins containing a namefragment
4. Lists all installed plugins for a particular group (input, filter, codec, output)



## Adding plugins to your deployment [installing-plugins]

When you have access to internet, you can retrieve plugins hosted on the [RubyGems.org](https://rubygems.org/)public repository and install them on top of your Logstash installation.

```shell
bin/logstash-plugin install logstash-input-github
```

After a plugin is successfully installed, you can use it in your configuration file.


## Updating plugins [updating-plugins]

Plugins have their own release cycles and are often released independently of Logstash’s core release cycle. Using the update subcommand you can get the latest version of the plugin.

```shell
bin/logstash-plugin update <1>
bin/logstash-plugin update logstash-input-github <2>
```

1. updates all installed plugins
2. updates only the plugin you specify



### Major version plugin updates [updating-major]

To avoid introducing breaking changes, the plugin manager updates only plugins for which newer *minor* or *patch* versions exist by default. If you wish to also include breaking changes, specify `--level=major`.

```shell
bin/logstash-plugin update --level=major <1>
bin/logstash-plugin update --level=major logstash-input-github <2>
```

1. updates all installed plugins to latest, including major versions with breaking changes
2. updates only the plugin you specify to latest, including major versions with breaking changes



## Removing plugins [removing-plugins]

If you need to remove plugins from your Logstash installation:

```shell
bin/logstash-plugin remove logstash-input-github
```


### Advanced: Adding a locally built plugin [installing-local-plugins]

In some cases, you may want to install plugins which are not yet released and not hosted on RubyGems.org. Logstash provides you the option to install a locally built plugin which is packaged as a ruby gem. Using a file location:

```shell
bin/logstash-plugin install /path/to/logstash-output-kafka-1.0.0.gem
```


### Advanced: Using `--path.plugins` [installing-local-plugins-path]

Using the Logstash `--path.plugins` flag, you can load a plugin source code located on your file system. Typically this is used by developers who are iterating on a custom plugin and want to test it before creating a ruby gem.

The path needs to be in a  specific directory hierarchy: `PATH/logstash/TYPE/NAME.rb`, where TYPE is *inputs* *filters*, *outputs* or *codecs* and NAME is the name of the plugin.

```shell
# supposing the code is in /opt/shared/lib/logstash/inputs/my-custom-plugin-code.rb
bin/logstash --path.plugins /opt/shared/lib
```






