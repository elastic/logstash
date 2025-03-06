---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/upgrading-using-direct-download.html
---

# Upgrading using a direct download [upgrading-using-direct-download]

This procedure downloads the relevant Logstash binaries directly from Elastic.

1. Shut down your Logstash pipeline, including any inputs that send events to Logstash.
2. Download the [Logstash installation file](https://www.elastic.co/downloads/logstash) that matches your host environment.
3. Backup your `config/` and `data/` folders in a temporary space.
4. Delete your Logstash directory.
5. Unpack the installation file into the folder that contained the Logstash directory that you just deleted.
6. Restore the `config/` and `data/` folders that were previously saved, overwriting the folders created during the unpack operation.
7. Test your configuration file with the `logstash --config.test_and_exit -f <configuration-file>` command. Configuration options for some Logstash plugins have changed.
8. Restart your Logstash pipeline after updating your configuration file.

