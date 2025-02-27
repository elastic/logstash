---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugin-generator.html
---

# Generating plugins [plugin-generator]

You can create your own Logstash plugin in seconds! The generate subcommand of `bin/logstash-plugin` creates the foundation for a new Logstash plugin with templatized files. It creates the correct directory structure, gemspec files, and dependencies so you can start adding custom code to process data with Logstash.

**Example Usage**

```sh
bin/logstash-plugin generate --type input --name xkcd --path ~/ws/elastic/plugins
```

* `--type`: Type of plugin - input, filter, output, or codec
* `--name`: Name for the new plugin
* `--path`: Directory path where the new plugin structure will be created. If you don’t specify a directory, the plugin is created in the current directory.
