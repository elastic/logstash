---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/installing-logstash.html
---

# Installing Logstash [installing-logstash]


## Installing from a Downloaded Binary [installing-binary]

The {{ls}} binaries are available from [https://www.elastic.co/downloads](https://www.elastic.co/downloads/logstash). Download the Logstash installation file for your host environment—​TAR.GZ, DEB, ZIP, or RPM.

Unpack the file. Do not install Logstash into a directory path that contains colon (:) characters.

::::{note}
These packages are free to use under the Elastic license. They contain open source and free commercial features and access to paid commercial features. [Start a 30-day trial](docs-content://deploy-manage/license/manage-your-license-in-self-managed-cluster.md) to try out all of the paid commercial features. See the [Subscriptions](https://www.elastic.co/subscriptions) page for information about Elastic license levels.

Alternatively, you can download an `oss` package, which contains only features that are available under the Apache 2.0 license.

::::


On supported Linux operating systems, you can use a package manager to install Logstash.


## Installing from Package Repositories [package-repositories]

We also have repositories available for APT and YUM based distributions. Note that we only provide binary packages, but no source packages, as the packages are created as part of the Logstash build.

We have split the Logstash package repositories by version into separate urls to avoid accidental upgrades across major versions. For all 9.x.y releases use 9.x as version number.

We use the PGP key [D88E42B4](https://pgp.mit.edu/pks/lookup?op=vindex&search=0xD27D666CD88E42B4), Elastic’s Signing Key, with fingerprint

```
4609 5ACC 8548 582C 1A26 99A9 D27D 666C D88E 42B4
```
to sign all our packages. It is available from [https://pgp.mit.edu](https://pgp.mit.edu).

::::{note}
When installing from a package repository (or from the DEB or RPM installation file), you will need to run Logstash as a service. Please refer to [Running Logstash as a Service](/reference/running-logstash.md) for more information.

For testing purposes, you may still run Logstash from the command line, but you may need to define the default setting options (described in [Logstash Directory Layout](/reference/dir-layout.md)) manually. Please refer to [Running Logstash from the Command Line](/reference/running-logstash-command-line.md) for more information.

::::



### APT [_apt]

Version 9.0.0 of Logstash has not yet been released.


### YUM [_yum]

Version 9.0.0 of Logstash has not yet been released.


### Docker [_docker]

Images are available for running Logstash as a Docker container. They are available from the Elastic Docker registry.

See [Running Logstash on Docker](/reference/docker.md) for details on how to configure and run Logstash Docker containers.

