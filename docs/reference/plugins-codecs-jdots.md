---
navigation_title: "jdots"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-jdots.html
---

# Jdots codec plugin [plugins-codecs-jdots]


**{{ls}} Core Plugin.** The jdots codec plugin cannot be installed or uninstalled independently of {{ls}}.

## Getting help [_getting_help_185]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash).


## Description [_description_184]

This codec renders each processed event as a dot (`.`). It is typically used with the `java_stdout` output to provide approximate event throughput. It is especially useful when combined with `pv` and `wc -c` as follows:

```bash
  bin/logstash -f /path/to/config/with/jdots/codec | pv | wc -c
```


