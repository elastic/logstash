---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/ecs-ls.html
---

# ECS in Logstash [ecs-ls]

The [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)) is an open source specification, developed with support from the Elastic user community. ECS defines a common set of fields to be used for storing event data, such as logs and metrics, in {{es}}. With ECS, users can normalize event data to better analyze, visualize, and correlate the data represented in their events.

## ECS compatibility [ecs-compatibility]

Many plugins implement an ECS-compatibility mode, which causes them to produce and manipulate events in a manner that is compatible with the Elastic Common Schema (ECS).

Any plugin that supports this mode will also have an `ecs_compatibility` option, which allows you to configure which mode the individual plugin instance should operate in. If left unspecified for an individual plugin, the pipeline’s `pipeline.ecs_compatibility` setting will be observed. This allows you to configure plugins to use a specific version of ECS or to use their legacy non-ECS behavior.

ECS compatibility modes do not prevent you from explicitly configuring a plugin in a manner that conflicts with ECS. Instead, they ensure that *implicit* configuration avoids conflicts.

### Configuring ECS [ecs-configuration]

In {{ls}} 8, all plugins are run in ECS compatibility v8 mode by default, but you can opt out at the plugin, pipeline, or system level to maintain legacy behavior. This can be helpful if you have very complex pipelines that were defined pre-ECS, to allow you to either upgrade them or to avoid doing so independently of your {{ls}} 8.x upgrade.

#### Specific plugin instance [_specific_plugin_instance]

Use a plugin’s `ecs_compatibility` option to override the default value on the plugin instance.

For example, if you want a specific instance of the GeoIP Filter to behave without ECS compatibility, you can adjust its definition in your pipeline without affecting any other plugin instances.

```text
filter {
  geoip {
    source => "[host][ip]"
    ecs_compatibility => disabled
  }
}
```

Alternatively, if you had a UDP input with a CEF codec, and wanted both to use an ECS mode while still running {{ls}} 7, you can adjust their definitions to specify the major version of ECS to use.

```text
input {
  udp {
    port => 1234
    ecs_compatibility => v8
    codec => cef {
      ecs_compatibility => v8
    }
  }
}
```


#### All plugins in a given pipeline [ecs-configuration-pipeline]

If you wish to provide a specific default value for `ecs_compatibility` to *all* plugins in a pipeline, you can do so with the `pipeline.ecs_compatibility` setting in your pipeline definition in `config/pipelines.yml` or Central Management. This setting will be used unless overridden by a specific plugin instance. If unspecified for an individual pipeline, the global value will be used.

For example, setting `pipeline.ecs_compatibility: disabled` for a pipeline *locks in* that pipeline’s pre-{{ls}} 8 behavior.

```yaml
- pipeline.id: my-legacy-pipeline
  path.config: "/etc/path/to/legacy-pipeline.config"
  pipeline.ecs_compatibility: disabled
- pipeline.id: my-ecs-pipeline
  path.config: "/etc/path/to/ecs-pipeline.config"
  pipeline.ecs_compatibility: v8
```


#### All plugins in all pipelines [ecs-configuration-all]

Similarly, you can set the default value for the whole {{ls}} process by setting the `pipeline.ecs_compatibility` value in `config/logstash.yml`.

```yaml
pipeline.ecs_compatibility: disabled
```




