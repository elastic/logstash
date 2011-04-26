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

<https://github.com/logstash/logstash-docs/tree/gh-pages/inputs>

## Filters

Each filter is documented here:

<https://github.com/logstash/logstash-docs/tree/gh-pages/filters>

## Outputs

Each output is documented here:

<https://github.com/logstash/logstash-docs/tree/gh-pages/outputs>

## Full examples

There are several example configs that ship with logstash:

<https://github.com/logstash/logstash/tree/master/etc/examples>
