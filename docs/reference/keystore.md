---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/keystore.html
---

# Secrets keystore for secure settings [keystore]

When you configure Logstash, you might need to specify sensitive settings or configuration, such as passwords. Rather than relying on file system permissions to protect these values, you can use the Logstash keystore to securely store secret values for use in configuration settings.

After adding a key and its secret value to the keystore, you can use the key in place of the secret value when you configure sensitive settings.

The syntax for referencing keys is identical to the syntax for [environment variables](/reference/environment-variables.md):

```txt
${KEY}
```

Where KEY is the name of the key.

**Example**

Imagine that the keystore contains a key called `ES_PWD` with the value `yourelasticsearchpassword`.

In configuration files, use:

```shell
output { elasticsearch {...password => "${ES_PWD}" } } }
```

In `logstash.yml`, use:

```shell
xpack.management.elasticsearch.password: ${ES_PWD}
```

Notice that the Logstash keystore differs from the Elasticsearch keystore. Whereas the Elasticsearch keystore lets you store `elasticsearch.yml` values by name, the Logstash keystore lets you specify arbitrary names that you can reference in the Logstash configuration.

::::{note}
There are some configuration fields that have no secret meaning, so not every field could leverage the secret store for variables substitution. Plugin’s `id` field is a field of this kind
::::


::::{note}
Referencing keystore data from `pipelines.yml` or the command line (`-e`) is not currently supported.
::::


::::{note}
Referencing keystore data from [centralized pipeline management](/reference/logstash-centralized-pipeline-management.md) requires each Logstash deployment to have a local copy of the keystore.
::::


::::{note}
The {{ls}} keystore needs to be protected, but the {{ls}} user must have access to the file. While most things in {{ls}} can be protected with `chown -R root:root <foo>`, the keystore itself must be accessible from the {{ls}} user. Use `chown logstash:root <keystore> && chmod 0600 <keystore>`.
::::


When Logstash parses the settings (`logstash.yml`) or configuration (`/etc/logstash/conf.d/*.conf`), it resolves keys from the keystore before resolving environment variables.


## Keystore password [keystore-password]

You can protect access to the Logstash keystore by storing a password in an environment variable called `LOGSTASH_KEYSTORE_PASS`. If you create the Logstash keystore after setting this variable, the keystore will be password protected. This means that the environment variable needs to be accessible to the running instance of Logstash. This environment variable must also be correctly set for any users who need to issue keystore commands (add, list, remove, etc.).

Using a keystore password is recommended, but optional. The data will be encrypted even if you do not set a password. However, it is highly recommended to configure the keystore password and grant restrictive permissions to any files that may contain the environment variable value. If you choose not to set a password, then you can skip the rest of this section.

For example:

```sh
set +o history
export LOGSTASH_KEYSTORE_PASS=mypassword
set -o history
bin/logstash-keystore create
```

This setup requires the user running Logstash to have the environment variable `LOGSTASH_KEYSTORE_PASS=mypassword` defined. If the environment variable is not defined, Logstash cannot access the keystore.

When you run Logstash from an RPM or DEB package installation, the environment variables are sourced from `/etc/sysconfig/logstash`.

::::{note}
You might need to create `/etc/sysconfig/logstash`. This file should be owned by `root` with `600` permissions. The expected format of `/etc/sysconfig/logstash` is `ENVIRONMENT_VARIABLE=VALUE`, with one entry per line.
::::


For other distributions, such as Docker or ZIP, see the documentation for your runtime environment (Windows, Docker, etc) to learn how to set the environment variable for the user that runs Logstash. Ensure that the environment variable (and thus the password) is only accessible to that user.


## Keystore location [keystore-location]

The keystore must be located in the Logstash `path.settings` directory. This is the same directory that contains the `logstash.yml` file. When performing any operation against the keystore, it is recommended to set `path.settings` for the keystore command. For example, to create a keystore on a RPM/DEB installation:

```sh
set +o history
export LOGSTASH_KEYSTORE_PASS=mypassword
set -o history
sudo -E /usr/share/logstash/bin/logstash-keystore --path.settings /etc/logstash create
```

See [Logstash Directory Layout](/reference/dir-layout.md) for more about the default directory locations.

::::{note}
You will see a warning if the `path.settings` is not pointed to the same directory as the `logstash.yml`.
::::



## Create or overwrite a keystore [creating-keystore]

The `create` command creates a new keystore or overwrites an existing keystore:

```sh
bin/logstash-keystore create
```

Creates the keystore in the directory defined in the `path.settings` setting.

::::{important}
If a keystore already exists, the `create` command can overwrite it (after a Y/N prompt). Selecting `Y` clears all keys and secrets that were previously stored.
::::


::::{tip}
Set a [keystore password](#keystore-password) when you create the keystore.
::::



## Add keys [add-keys-to-keystore]

To store sensitive values, such as authentication credentials for Elasticsearch, use the `add` command:

```sh
bin/logstash-keystore add ES_USER ES_PWD
```

When prompted, enter a value for each key.

::::{note}
Key values are limited to:

* {applies_to}`stack: ga 9.0.1+!` ASCII letters (`a`-`z`, `A`-`Z`), numbers (`0`-`9`), underscores (`_`), and dots (`.`). Key values must be at least one character long and cannot begin with a number.
* {applies_to}`stack: ga =9.0.0!` ASCII characters including digits, letters, and a few special symbols.
::::



## List keys [list-settings]

To list the keys defined in the keystore, use:

```sh
bin/logstash-keystore list
```


## Remove keys [remove-settings]

To remove keys from the keystore, use:

```sh
bin/logstash-keystore remove ES_USER ES_PWD
```
