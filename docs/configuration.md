---
title: Configuration Language - logstash
layout: content_right
---
# LogStash Config Language

The logstash config language aims to be simple.

There's 3 main sections: inputs, filters, outputs. Each section has
configurations for each plugin available in that section.

Example:

    inputs {
      ...
    }

    filters {
      ...
    }

    outputs {
      ...
    }

## Filters

For a given event, are applied in the order of appearance in the config file.

## Further reading

For more information, see (the plugin docs index)[index]
