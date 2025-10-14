---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/configuring-geoip-database-management.html
---

# Configure GeoIP Database Management [configuring-geoip-database-management]

To configure [GeoIP Database Management](/reference/logstash-geoip-database-management.md):

1. Verify that you are using a license that includes the geoip database management feature.

    For more information, see [https://www.elastic.co/subscriptions](https://www.elastic.co/subscriptions) and [License management](docs-content://deploy-manage/license/manage-your-license-in-self-managed-cluster.md).

2. Specify [geoip database management settings](#geoip-database-management-settings) in the `logstash.yml` file to tune the configuration as-needed.

## GeoIP database Management settings in {{ls}} [geoip-database-management-settings]


You can set the following `xpack.geoip` settings in `logstash.yml` to configure the [geoip database manager](/reference/logstash-geoip-database-management.md). For more information about configuring Logstash, see [logstash.yml](/reference/logstash-settings-file.md).

`xpack.geoip.downloader.enabled`
:   (Boolean) If `true`, Logstash automatically downloads and manages updates for GeoIP2 databases from the `xpack.geoip.downloader.endpoint`. If `false`, Logstash does not manage GeoIP2 databases and plugins that need a GeoIP2 database must be configured to provide their own.

`xpack.geoip.downloader.endpoint`
:   (String) Endpoint URL used to download updates for GeoIP2 databases. For example, `https://example.com/overview.json`. Defaults to `https://geoip.elastic.co/v1/database`. Note that Logstash will periodically make a GET request to `${xpack.geoip.downloader.endpoint}?elastic_geoip_service_tos=agree`, expecting the list of metadata about databases typically found in `overview.json`.

`xpack.geoip.downloader.poll.interval`
:   (Time Value) How often Logstash checks for GeoIP2 database updates at the `xpack.geoip.downloader.endpoint`. For example, `6h` to check every six hours. Defaults to `24h` (24 hours).


## Offline and air-gapped environments [configuring-geoip-database-management-offline]

If Logstash does not have access to the internet, or if you want to disable the database manager, set the `xpack.geoip.downloader.enabled` value to `false` in `logstash.yml`. When the database manager is disabled, plugins that require GeoIP lookups must be configured with their own source of GeoIP databases.

### Using an HTTP proxy [_using_an_http_proxy]

If you can’t connect directly to the Elastic GeoIP endpoint, consider setting up an HTTP proxy server. You can then specify the proxy with `http_proxy` environment variable.

```sh
export http_proxy="http://PROXY_IP:PROXY_PORT"
```


### Using a custom endpoint [_using_a_custom_endpoint]

If you work in an air-gapped environment and can’t update your databases from the Elastic endpoint, You can then download databases from MaxMind and bootstrap the service.

1. Download both `GeoLite2-ASN.mmdb` and `GeoLite2-City.mmdb` database files from the [MaxMind site](http://dev.maxmind.com/geoip/geoip2/geolite2).
2. Copy both database files to a single directory.
3. [Download {{es}}](https://www.elastic.co/downloads/elasticsearch).
4. From your {{es}} directory, run:

    ```sh
    ./bin/elasticsearch-geoip -s my/database/dir
    ```

5. Serve the static database files from your directory. For example, you can use Docker to serve the files from nginx server:

    ```sh
    docker run -p 8080:80 -v my/database/dir:/usr/share/nginx/html:ro nginx
    ```

6. Specify the service’s endpoint URL in Logstash using the `xpack.geoip.download.endpoint=http://localhost:8080/overview.json` setting in `logstash.yml`.

Logstash gets automatic updates from this service.



