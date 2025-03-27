---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/docker-config.html
---

# Configuring Logstash for Docker [docker-config]

Logstash differentiates between two types of configuration: [Settings and Pipeline Configuration](/reference/config-setting-files.md).

## Pipeline Configuration [_pipeline_configuration]

It is essential to place your pipeline configuration where it can be found by Logstash. By default, the container will look in `/usr/share/logstash/pipeline/` for pipeline configuration files.

In this example we use a bind-mounted volume to provide the configuration via the `docker run` command:

```sh
docker run --rm -it -v ~/pipeline/:/usr/share/logstash/pipeline/ docker.elastic.co/logstash/logstash:9.0.0
```

Every file in the host directory `~/pipeline/` will then be parsed by Logstash as pipeline configuration.

If you don’t provide configuration to Logstash, it will run with a minimal config that listens for messages from the [Beats input plugin](logstash-docs-md://lsr/plugins-inputs-beats.md) and echoes any that are received to `stdout`. In this case, the startup logs will be similar to the following:

```text
Sending Logstash logs to /usr/share/logstash/logs which is now configured via log4j2.properties.
[2016-10-26T05:11:34,992][INFO ][logstash.inputs.beats    ] Beats inputs: Starting input listener {:address=>"0.0.0.0:5044"}
[2016-10-26T05:11:35,068][INFO ][logstash.pipeline        ] Starting pipeline {"id"=>"main", "pipeline.workers"=>4, "pipeline.batch.size"=>125, "pipeline.batch.delay"=>5, "pipeline.max_inflight"=>500}
[2016-10-26T05:11:35,078][INFO ][org.logstash.beats.Server] Starting server on port: 5044
[2016-10-26T05:11:35,078][INFO ][logstash.pipeline        ] Pipeline main started
[2016-10-26T05:11:35,105][INFO ][logstash.agent           ] Successfully started Logstash API endpoint {:port=>9600}
```

This is the default configuration for the image, defined in `/usr/share/logstash/pipeline/logstash.conf`.  If this is the behaviour that you are observing, ensure that your pipeline configuration is being picked up correctly, and that you are replacing either `logstash.conf` or the entire `pipeline` directory.


## Settings [_settings]

The image provides several methods for configuring settings. The conventional approach is to provide a custom `logstash.yml` file, but it’s also possible to use environment variables to define settings.

### Bind-mounted settings files [docker-bind-mount-settings]

Settings files can also be provided through bind-mounts. Logstash expects to find them at `/usr/share/logstash/config/`.

It’s possible to provide an entire directory containing all needed files:

```sh
docker run --rm -it -v ~/settings/:/usr/share/logstash/config/ docker.elastic.co/logstash/logstash:9.0.0
```

Alternatively, a single file can be mounted:

```sh
docker run --rm -it -v ~/settings/logstash.yml:/usr/share/logstash/config/logstash.yml docker.elastic.co/logstash/logstash:9.0.0
```

::::{note}
Bind-mounted configuration files will retain the same permissions and ownership within the container that they have on the host system. Be sure to set permissions such that the files will be readable and, ideally, not writeable by the container’s `logstash` user (UID 1000).
::::



### Custom Images [_custom_images]

Bind-mounted configuration is not the only option, naturally. If you prefer the *Immutable Infrastructure* approach, you can prepare a custom image containing your configuration by using a `Dockerfile` like this one:

```dockerfile
FROM docker.elastic.co/logstash/logstash:9.0.0
RUN rm -f /usr/share/logstash/pipeline/logstash.conf
COPY pipeline/ /usr/share/logstash/pipeline/
COPY config/ /usr/share/logstash/config/
```

Be sure to replace or delete `logstash.conf` in your custom image, so that you don’t retain the example config from the base image.


### Environment variable configuration [docker-env-config]

Under Docker, Logstash settings can be configured via environment variables. When the container starts, a helper process checks the environment for variables that can be mapped to Logstash settings. Settings that are found in the environment override those in the `logstash.yml` as the container starts up.

For compatibility with container orchestration systems, these environment variables are written in all capitals, with underscores as word separators.

Some example translations are shown here:

**Environment Variable**
:   **Logstash Setting**

`PIPELINE_WORKERS`
:   `pipeline.workers`

`LOG_LEVEL`
:   `log.level`

`MONITORING_ENABLED`
:   `monitoring.enabled`

In general, any setting listed in the [settings documentation](/reference/logstash-settings-file.md) can be configured with this technique.

::::{note}
Defining settings with environment variables causes `logstash.yml` to be modified in place. This behaviour is likely undesirable if `logstash.yml` was bind-mounted from the host system. Thus, it is not recommended to combine the bind-mount technique with the environment variable technique. It is best to choose a single method for defining Logstash settings.
::::




## Docker defaults [_docker_defaults]

The following settings have different default values when using the Docker images:

`api.http.host`
:   `0.0.0.0`

`monitoring.elasticsearch.hosts`
:   `http://elasticsearch:9200`

::::{note}
The setting `monitoring.elasticsearch.hosts` is not defined in the `-oss` image.
::::


These settings are defined in the default `logstash.yml`. They can be overridden with a [custom `logstash.yml`](#docker-bind-mount-settings) or via [environment variables](#docker-env-config).

::::{important}
If replacing `logstash.yml` with a custom version, be sure to copy the above defaults to the custom file if you want to retain them. If not, they will be "masked" by the new file.
::::



## Logging Configuration [_logging_configuration]

Under Docker, Logstash logs go to standard output by default. To change this behaviour, use any of the techniques above to replace the file at `/usr/share/logstash/config/log4j2.properties`.
