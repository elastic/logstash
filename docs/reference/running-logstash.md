---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/running-logstash.html
---

# Running Logstash as a Service on Debian or RPM [running-logstash]

Logstash is not started automatically after installation. Starting and stopping Logstash depends on the init system of the underlying operating system, which is now systemd.

As systemd is now the de-facto init system, here are some common operating systems and versions that use it.  This list is intended to be informative, not exhaustive.

| Distribution | Service System |
| --- | --- |
| Ubuntu 16.04 and newer | [systemd](#running-logstash-systemd) |
| Debian 8 "jessie" and newer | [systemd](#running-logstash-systemd) |
| CentOS (and RHEL) 7 and newer | [systemd](#running-logstash-systemd) |

## Running Logstash by Using Systemd [running-logstash-systemd]

Distributions like Debian Jessie, Ubuntu 15.10+, and many of the SUSE derivatives use systemd and the `systemctl` command to start and stop services. Logstash places the systemd unit files in `/etc/systemd/system` for both deb and rpm. After installing the package, you can start up Logstash with:

```sh
sudo systemctl start logstash.service
```


