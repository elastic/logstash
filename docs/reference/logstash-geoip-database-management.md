---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/logstash-geoip-database-management.html
---

# GeoIP Database Management [logstash-geoip-database-management]

Logstash provides a mechanism for provisioning and maintaining GeoIP databases, which plugins can use to ensure that they have access to an always-up-to-date and EULA-compliant database for geo enrichment. This mechanism requires internet access or a network route to an Elastic GeoIP database service.

If the database manager is enabled in `logstash.yml` (as it is by default), a plugin may subscribe to a database, triggering a download if a valid database is not already available. Logstash checks for updates every day. When an updated database is discovered, it is downloaded in the background and made available to the plugins that rely on it.

The GeoIP databases are separately-licensed from MaxMind under the terms of an End User License Agreement, which prohibits a database from being used after an update has been available for more than 30 days. When Logstash cannot reach the database service for 30 days or more to validate that a managed database is up-to-date, that database is deleted and made unavailable to the plugins that subscribed to it.

::::{note}
GeoIP database management is a licensed feature of Logstash, and is only available in the Elastic-licensed complete distribution of Logstash.
::::


## Database Metrics [logstash-geoip-database-management-metrics]

You can monitor the managed database’s status through the [Node Stats API](https://www.elastic.co/docs/api/doc/logstash/operation/operation-nodestats).

The following request returns a JSON document containing database manager stats, including:

* database status and freshness

    * `geoip_download_manager.database.*.status`

        * `init` : initial CC database status
        * `up_to_date` : using up-to-date EULA database
        * `to_be_expired` : 25 days without calling service
        * `expired` : 30 days without calling service

    * `fail_check_in_days` : number of days Logstash fails to call service since the last success

* info about download successes and failures

    * `geoip_download_manager.download_stats.successes` number of successful checks and downloads
    * `geoip_download_manager.download_stats.failures` number of failed check or download
    * `geoip_download_manager.download_stats.status`

        * `updating` : check and download at the moment
        * `succeeded` : last download succeed
        * `failed` : last download failed


```js
curl -XGET 'localhost:9600/_node/stats/geoip_download_manager?pretty'
```

Example response:

```js
{
  "geoip_download_manager" : {
    "database" : {
      "ASN" : {
        "status" : "up_to_date",
        "fail_check_in_days" : 0,
        "last_updated_at": "2021-06-21T16:06:54+02:00"
      },
      "City" : {
        "status" : "up_to_date",
        "fail_check_in_days" : 0,
        "last_updated_at": "2021-06-21T16:06:54+02:00"
      }
    },
    "download_stats" : {
      "successes" : 15,
      "failures" : 1,
      "last_checked_at" : "2021-06-21T16:07:03+02:00",
      "status" : "succeeded"
    }
  }
}
```


