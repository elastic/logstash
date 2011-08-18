---
title: Metrics from Logs - logstash
layout: content_right
---
# Pull metrics from logs

Logs are more than just text. How many customers signed up today? How many HTTP
errors happened this week? When was your last puppet run?

Apache logs give you the http response code and bytes sent - that's useful in a
graph. Metrics occur in logs so frequently there are piles of tools available to
help process them.

Logstash can help.

## Keep it simple.

[Etsy](https://github.com/etsy] has some excellent open source tools. One of
them, [logster](https://github.com/etsy/logster), is meant to help you pull
metrics from logs and ship them to [graphite](http://graphite.wikidot.com/) so
you can make pretty graphs of those metrics.

One sample logster parser is one that pulls http response codes out of your
apache logs: (SampleLogster.py)[https://github.com/etsy/logster/blob/master/parsers/SampleLogster.py]

The above code is roughly 50 lines of python and only solves one specific
problem in only apache logs (count http response codes by major number (1xx,
2xx, 3xx, etc).

Logstash can do this simpler:

    input {
      file { path => "/var/log/apache/access.log" }
    }

    filter {
      grok { pattern => "%{COMBINEDAPACHELOG}" }
    }

    output {
      statsd { increment => "apache.response.%{response}" }
    }

The above uses grok to parse fields out of apache logs and using the statsd
output to increment counters based on the response code. Of course, now that we
are parsing apache logs fully, we can trivially add additional metrics:

    output {
      statsd {
        increment => [
          "apache.response.%{response}",
          "apache.bytes.%{bytes}",
        ]
      }
    }

Now adding additional metrics is just one more line in your logstash config file.

![apache response codes graphed with graphite, fed data with logstash](media/frontend-response-codes.png)

