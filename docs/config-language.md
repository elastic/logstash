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

## Inputs

Each input is documented here:

<inputs>

## Filters

For each event, filters are applied in order of appearance in the config file.

For example, pulling a timestamp out of a syslog event, you'll want to use
grok to pull out the time string, first, then use a date filter to 

Each filter is documented here:

<filters>

## Outputs

Each output is documented here:

<outputs>

## Full examples

There are several example configs that ship with logstash:

<https://github.com/logstash/logstash/tree/master/etc/examples>
