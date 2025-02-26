---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/upgrading-using-package-managers.html
---

# Upgrading using package managers [upgrading-using-package-managers]

This procedure uses [package managers](/reference/installing-logstash.md#package-repositories) to upgrade Logstash.

1. Shut down your Logstash pipeline, including any inputs that send events to Logstash.
2. Using the directions in the [Installing from Package Repositories](/reference/installing-logstash.md#package-repositories) section, update your repository links to point to the 9.x repositories.
3. Run the `apt-get upgrade logstash` or `yum update logstash` command as appropriate for your operating system.
4. Test your configuration file with the `logstash --config.test_and_exit -f <configuration-file>` command. Configuration options for some Logstash plugins have changed in the 9.x release.
5. Restart your Logstash pipeline after you have updated your configuration file.

