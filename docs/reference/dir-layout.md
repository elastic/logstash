---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/dir-layout.html
---

# Logstash Directory Layout [dir-layout]

This section describes the default directory structure that is created when you unpack the Logstash installation packages.

## Directory Layout of `.zip` and `.tar.gz` Archives [zip-targz-layout]

The `.zip` and `.tar.gz` packages are entirely self-contained. All files and directories are, by default, contained within the home directory - the directory created when unpacking the archive.

This is very convenient because you don’t have to create any directories to start using Logstash, and uninstalling Logstash is as easy as removing the home directory.  However, it is advisable to change the default locations of the config and the logs directories so that you do not delete important data later on.

| Type | Description | Default Location | Setting |
| --- | --- | --- | --- |
| home | Home directory of the Logstash installation. | `{extract.path}`- Directory created by unpacking the archive |  |
| bin | Binary scripts, including `logstash` to start Logstash    and `logstash-plugin` to install plugins | `{extract.path}/bin` |  |
| settings | Configuration files, including `logstash.yml` and `jvm.options` | `{extract.path}/config` | `path.settings` |
| logs | Log files | `{extract.path}/logs` | `path.logs` |
| plugins | Local, non Ruby-Gem plugin files. Each plugin is contained in a subdirectory. Recommended for development only. | `{extract.path}/plugins` | `path.plugins` |
| data | Data files used by logstash and its plugins for any persistence needs. | `{extract.path}/data` | `path.data` |


## Directory Layout of Debian and RPM Packages [deb-layout]

The Debian package and the RPM package each place config files, logs, and the settings files in the appropriate locations for the system:

| Type | Description | Default Location | Setting |
| --- | --- | --- | --- |
| home | Home directory of the Logstash installation. | `/usr/share/logstash` |  |
| bin | Binary scripts including `logstash` to start Logstash    and `logstash-plugin` to install plugins | `/usr/share/logstash/bin` |  |
| settings | Configuration files, including `logstash.yml` and `jvm.options` | `/etc/logstash` | `path.settings` |
| conf | Logstash pipeline configuration files | `/etc/logstash/conf.d/*.conf` | See `/etc/logstash/pipelines.yml` |
| logs | Log files | `/var/log/logstash` | `path.logs` |
| plugins | Local, non Ruby-Gem plugin files. Each plugin is contained in a subdirectory. Recommended for development only. | `/usr/share/logstash/plugins` | `path.plugins` |
| data | Data files used by logstash and its plugins for any persistence needs. | `/var/lib/logstash` | `path.data` |


## Directory Layout of Docker Images [docker-layout]

The Docker images are created from the `.tar.gz` packages, and follow a similar directory layout.

| Type | Description | Default Location | Setting |
| --- | --- | --- | --- |
| home | Home directory of the Logstash installation. | `/usr/share/logstash` |  |
| bin | Binary scripts, including `logstash` to start Logstash    and `logstash-plugin` to install plugins | `/usr/share/logstash/bin` |  |
| settings | Configuration files, including `logstash.yml` and `jvm.options` | `/usr/share/logstash/config` | `path.settings` |
| conf | Logstash pipeline configuration files | `/usr/share/logstash/pipeline` | `path.config` |
| plugins | Local, non Ruby-Gem plugin files. Each plugin is contained in a subdirectory. Recommended for development only. | `/usr/share/logstash/plugins` | `path.plugins` |
| data | Data files used by logstash and its plugins for any persistence needs. | `/usr/share/logstash/data` | `path.data` |

::::{note}
Logstash Docker containers do not create log files by default. They log to standard output.
::::



