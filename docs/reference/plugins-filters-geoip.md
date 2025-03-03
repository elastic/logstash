---
navigation_title: "geoip"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-geoip.html
---

# Geoip filter plugin [plugins-filters-geoip]


* Plugin version: v7.3.1
* Released on: 2024-10-11
* [Changelog](https://github.com/logstash-plugins/logstash-filter-geoip/blob/v7.3.1/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-geoip-index.md).

## Getting help [_getting_help_142]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-geoip). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_141]

The GeoIP filter adds information about the geographical location of IP addresses, based on data from the MaxMind GeoLite2 databases.


## Supported Databases [_supported_databases]

This plugin is bundled with [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2) City database out of the box. From MaxMind’s description — "GeoLite2 databases are free IP geolocation databases comparable to, but less accurate than, MaxMind’s GeoIP2 databases". Please see GeoIP Lite2 license for more details.

[Commercial databases](https://www.maxmind.com/en/geoip2-databases) from MaxMind are also supported in this plugin.

If you need to use databases other than the bundled GeoLite2 City, you can download them directly from MaxMind’s website and use the `database` option to specify their location. The GeoLite2 databases can be [downloaded from here](https://dev.maxmind.com/geoip/geoip2/geolite2).

If you would like to get Autonomous System Number(ASN) information, you can use the GeoLite2-ASN database.


## Database License [plugins-filters-geoip-database_license]

[MaxMind](https://www.maxmind.com) changed from releasing the GeoIP database under a Creative Commons (CC) license to a proprietary end-user license agreement (EULA).  The MaxMind EULA requires Logstash to update the MaxMind database within 30 days of a database update.

The GeoIP filter plugin can manage the database for users running the Logstash default distribution, or you can manage database updates on your own. The behavior is controlled by the `database` setting and by the auto-update feature. When you use the default `database` setting and the auto-update feature is enabled, Logstash ensures that the plugin is using the latest version of the database. Otherwise, you are responsible for maintaining compliance.

The Logstash open source distribution uses the MaxMind Creative Commons license database by default.


## Database Auto-update [plugins-filters-geoip-database_auto]

This plugin bundles Creative Commons (CC) license databases. If the auto-update feature is enabled in `logstash.yml`(as it is by default), Logstash checks for database updates every day. It downloads the latest and can replace the old database while the plugin is running.

::::{note}
If the auto-update feature is disabled or the database has never been updated successfully, as in air-gapped environments, Logstash can use CC license databases indefinitely.
::::


After Logstash has switched to a EULA licensed database, the geoip filter will stop enriching events in order to maintain compliance if Logstash fails to check for database updates for 30 days. Events will be tagged with `_geoip_expired_database` tag to facilitate the handling of this situation.

::::{note}
If the auto-update feature is enabled, Logstash upgrades from the CC database license to the EULA version on the first download.
::::


::::{tip}
When possible, allow Logstash to access the internet to download databases so that they are always up-to-date.
::::


**Disable the auto-update feature**

If you work in air-gapped environment and want to disable the database auto-update feature, set the `xpack.geoip.downloader.enabled` value to `false` in `logstash.yml`.

When the auto-update feature is disabled, Logstash uses the Creative Commons (CC) license databases indefinitely, and any previously downloaded version of the EULA databases will be deleted.


## Manage your own database updates [plugins-filters-geoip-manage_update]

**Use an HTTP proxy**

If you can’t connect directly to the Elastic GeoIP endpoint, consider setting up an HTTP proxy server. You can then specify the proxy with `http_proxy` environment variable.

```sh
export http_proxy="http://PROXY_IP:PROXY_PORT"
```

**Use a custom endpoint (air-gapped environments)**

If you work in air-gapped environment and can’t update your databases from the Elastic endpoint, You can then download databases from MaxMind and bootstrap the service.

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

6. Specify the service’s endpoint URL using the `xpack.geoip.download.endpoint=http://localhost:8080/overview.json` setting in `logstash.yml`.

Logstash gets automatic updates from this service.


## Database Metrics [plugins-filters-geoip-metrics]

You can monitor database status through the [Node Stats API](https://www.elastic.co/docs/api/doc/logstash/operation/operation-nodestats).

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


## Field mapping [plugins-filters-geoip-field-mapping]

When this plugin is run with [`ecs_compatibility`](#plugins-filters-geoip-ecs_compatibility) disabled, the MaxMind DB’s fields are added directly to the [`target`](#plugins-filters-geoip-target). When ECS compatibility is enabled, the fields are structured to fit into an ECS shape.

| Database Field Name | ECS Field | Example |
| --- | --- | --- |
| `ip` | `[ip]` | `12.34.56.78` |
| `anonymous` | `[ip_traits][anonymous]` | `false` |
| `anonymous_vpn` | `[ip_traits][anonymous_vpn]` | `false` |
| `hosting_provider` | `[ip_traits][hosting_provider]` | `true` |
| `network` | `[ip_traits][network]` | `12.34.56.78/20` |
| `public_proxy` | `[ip_traits][public_proxy]` | `true` |
| `residential_proxy` | `[ip_traits][residential_proxy]` | `false` |
| `tor_exit_node` | `[ip_traits][tor_exit_node]` | `true` |
| `city_name` | `[geo][city_name]` | `Seattle` |
| `country_name` | `[geo][country_name]` | `United States` |
| `continent_code` | `[geo][continent_code]` | `NA` |
| `continent_name` | `[geo][continent_name]` | `North America` |
| `country_code2` | `[geo][country_iso_code]` | `US` |
| `country_code3` | *N/A* | `US`<br>                                                           *maintained for legacy                                                           support, but populated                                                           with 2-character country                                                           code* |
| `postal_code` | `[geo][postal_code]` | `98106` |
| `region_name` | `[geo][region_name]` | `Washington` |
| `region_code` | `[geo][region_code]` | `WA` |
| `region_iso_code`* | `[geo][region_iso_code]` | `US-WA` |
| `timezone` | `[geo][timezone]` | `America/Los_Angeles` |
| `location`* | `[geo][location]` | `{"lat": 47.6062, "lon": -122.3321}"` |
| `latitude` | `[geo][location][lat]` | `47.6062` |
| `longitude` | `[geo][location][lon]` | `-122.3321` |
| `domain` | `[domain]` | `example.com` |
| `asn` | `[as][number]` | `98765` |
| `as_org` | `[as][organization][name]` | `Elastic, NV` |
| `isp` | `[mmdb][isp]` | `InterLink Supra LLC` |
| `dma_code` | `[mmdb][dma_code]` | `819` |
| `organization` | `[mmdb][organization]` | `Elastic, NV` |

::::{note}
`*` indicates a composite field, which is only populated if GeoIP lookup result contains all components.
::::



## Details [_details_2]

When using a City database, the enrichment is aborted if no latitude/longitude pair is available.

The `location` field combines the latitude and longitude into a structure called [GeoJSON](https://datatracker.ietf.org/doc/html/rfc7946). When you are using a default [`target`](#plugins-filters-geoip-target), the templates provided by the [elasticsearch output](/reference/plugins-outputs-elasticsearch.md) map the field to an [Elasticsearch Geo_point datatype](elasticsearch://reference/elasticsearch/mapping-reference/geo-point.md).

As this field is a `geo_point` *and* it is still valid GeoJSON, you get the awesomeness of Elasticsearch’s geospatial query, facet and filter functions and the flexibility of having GeoJSON for all other applications (like Kibana’s map visualization).

::::{note}
This product includes GeoLite2 data created by MaxMind, available from [http://www.maxmind.com](http://www.maxmind.com). This database is licensed under [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Versions 4.0.0 and later of the GeoIP filter use the MaxMind GeoLite2 database and support both IPv4 and IPv6 lookups. Versions prior to 4.0.0 use the legacy MaxMind GeoLite database and support IPv4 lookups only.

::::



## Geoip Filter Configuration Options [plugins-filters-geoip-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-geoip-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`cache_size`](#plugins-filters-geoip-cache_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`database`](#plugins-filters-geoip-database) | a valid filesystem path | No |
| [`default_database_type`](#plugins-filters-geoip-default_database_type) | `City` or `ASN` | No |
| [`ecs_compatibility`](#plugins-filters-geoip-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`fields`](#plugins-filters-geoip-fields) | [array](/reference/configuration-file-structure.md#array) | No |
| [`source`](#plugins-filters-geoip-source) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`tag_on_failure`](#plugins-filters-geoip-tag_on_failure) | [array](/reference/configuration-file-structure.md#array) | No |
| [`target`](#plugins-filters-geoip-target) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-filters-geoip-common-options) for a list of options supported by all filter plugins.

 

### `cache_size` [plugins-filters-geoip-cache_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1000`

GeoIP lookup is surprisingly expensive. This filter uses an cache to take advantage of the fact that IPs agents are often found adjacent to one another in log files and rarely have a random distribution. The higher you set this the more likely an item is to be in the cache and the faster this filter will run. However, if you set this too high you can use more memory than desired. Since the Geoip API upgraded to v2, there is not any eviction policy so far, if cache is full, no more record can be added. Experiment with different values for this option to find the best performance for your dataset.

This MUST be set to a value > 0. There is really no reason to not want this behavior, the overhead is minimal and the speed gains are large.

It is important to note that this config value is global to the geoip_type. That is to say all instances of the geoip filter of the same geoip_type share the same cache. The last declared cache size will *win*. The reason for this is that there would be no benefit to having multiple caches for different instances at different points in the pipeline, that would just increase the number of cache misses and waste memory.


### `database` [plugins-filters-geoip-database]

* Value type is [path](/reference/configuration-file-structure.md#path)
* If not specified, the database defaults to the `GeoLite2 City` database that ships with Logstash.

The path to MaxMind’s database file that Logstash should use. The default database is `GeoLite2-City`. This plugin supports several free databases (`GeoLite2-City`, `GeoLite2-Country`, `GeoLite2-ASN`) and a selection of commercially-licensed databases (`GeoIP2-City`, `GeoIP2-ISP`, `GeoIP2-Country`, `GeoIP2-Domain`, `GeoIP2-Enterprise`, `GeoIP2-Anonymous-IP`).

Database auto-update applies to the default distribution. When `database` points to user’s database path, auto-update is disabled. See [Database License](#plugins-filters-geoip-database_license) for more information.


### `default_database_type` [plugins-filters-geoip-default_database_type]

This plugin now includes both the GeoLite2-City and GeoLite2-ASN databases.  If `database` and `default_database_type` are unset, the GeoLite2-City database will be selected.  To use the included GeoLite2-ASN database, set `default_database_type` to `ASN`.

* Value type is [string](/reference/configuration-file-structure.md#string)
* The default value is `City`
* The only acceptable values are `City` and `ASN`


### `fields` [plugins-filters-geoip-fields]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

An array of geoip fields to be included in the event.

Possible fields depend on the database type. By default, all geoip fields from the relevant database are included in the event.

For a complete list of available fields and how they map to an event’s structure, see [field mapping](#plugins-filters-geoip-field-mapping).


### `ecs_compatibility` [plugins-filters-geoip-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: unstructured geo data added at root level
    * `v1`, `v8`: use fields that are compatible with Elastic Common Schema. Example: `[client][geo][country_name]`. See [field mapping](#plugins-filters-geoip-field-mapping) for more info.

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). The value of this setting affects the *default* value of [`target`](#plugins-filters-geoip-target).


### `source` [plugins-filters-geoip-source]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The field containing the IP address or hostname to map via geoip. If this field is an array, only the first value will be used.


### `tag_on_failure` [plugins-filters-geoip-tag_on_failure]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["_geoip_lookup_failure"]`

Tags the event on failure to look up geo information. This can be used in later analysis.


### `target` [plugins-filters-geoip-target]

* This is an optional setting with condition.
* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value depends on whether [`ecs_compatibility`](#plugins-filters-geoip-ecs_compatibility) is enabled:

    * ECS Compatibility disabled: `geoip`
    * ECS Compatibility enabled: If `source` is an `ip` sub-field, eg. `[client][ip]`, `target` will automatically set to the parent field, in this example `client`, otherwise, `target` is a required setting

        * `geo` field is nested in `[client][geo]`
        * ECS compatible values are `client`, `destination`, `host`, `observer`, `server`, `source`


Specify the field into which Logstash should store the geoip data. This can be useful, for example, if you have `src_ip` and `dst_ip` fields and would like the GeoIP information of both IPs.

If you save the data to a target field other than `geoip` and want to use the `geo_point` related functions in Elasticsearch, you need to alter the template provided with the Elasticsearch output and configure the output to use the new template.

Even if you don’t use the `geo_point` mapping, the `[target][location]` field is still valid GeoJSON.



## Common options [plugins-filters-geoip-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-geoip-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-geoip-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-geoip-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-geoip-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-geoip-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-geoip-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-geoip-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-geoip-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      geoip {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      geoip {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-geoip-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      geoip {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      geoip {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-geoip-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-geoip-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 geoip filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      geoip {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-geoip-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-geoip-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      geoip {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      geoip {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-geoip-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      geoip {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      geoip {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.
