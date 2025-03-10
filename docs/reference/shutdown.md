---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/shutdown.html
---

# Shutting Down Logstash [shutdown]

If you’re running {{ls}} as a service, use one of the following commands to stop it:

* On systemd, use:

    ```shell
    systemctl stop logstash
    ```


If you’re running {{ls}} directly in the console on a POSIX system, you can stop it by sending SIGTERM to the {{ls}} process. For example:

```shell
kill -TERM {logstash_pid}
```

Alternatively, enter **Ctrl-C** in the console.

## What Happens During a Controlled Shutdown? [_what_happens_during_a_controlled_shutdown]

When you attempt to shut down a running Logstash instance, Logstash performs several steps before it can safely shut down. It must:

* Stop all input, filter and output plugins
* Process all in-flight events
* Terminate the Logstash process

The following conditions affect the shutdown process:

* An input plugin receiving data at a slow pace.
* A slow filter, like a Ruby filter executing `sleep(10000)` or an Elasticsearch filter that is executing a very heavy query.
* A disconnected output plugin that is waiting to reconnect to flush in-flight events.

These situations make the duration and success of the shutdown process unpredictable.

Logstash has a stall detection mechanism that analyzes the behavior of the pipeline and plugins during shutdown. This mechanism produces periodic information about the count of inflight events in internal queues and a list of busy worker threads.

To enable Logstash to forcibly terminate in the case of a stalled shutdown, use the `--pipeline.unsafe_shutdown` flag when you start Logstash.

::::{warning}
Unsafe shutdowns, force-kills of the Logstash process, or crashes of the Logstash process for any other reason may result in data loss (unless you’ve enabled Logstash to use [persistent queues](/reference/persistent-queues.md)). Shut down Logstash safely whenever possible.
::::



## Stall Detection Example [shutdown-stall-example]

In this example, slow filter execution prevents the pipeline from performing a clean shutdown. Because Logstash is started with the `--pipeline.unsafe_shutdown` flag, the shutdown results in the loss of 20 events.

::::{admonition}
```shell
bin/logstash -e 'input { generator { } } filter { ruby { code => "sleep 10000" } }
  output { stdout { codec => dots } }' -w 1 --pipeline.unsafe_shutdown
Pipeline main started
^CSIGINT received. Shutting down the agent. {:level=>:warn}
stopping pipeline {:id=>"main", :level=>:warn}
Received shutdown signal, but pipeline is still waiting for in-flight events
to be processed. Sending another ^C will force quit Logstash, but this may cause
data loss. {:level=>:warn}
{"inflight_count"=>125, "stalling_thread_info"=>{["LogStash::Filters::Ruby",
{"code"=>"sleep 10000"}]=>[{"thread_id"=>19, "name"=>"[main]>worker0",
"current_call"=>"(ruby filter code):1:in `sleep'"}]}} {:level=>:warn}
The shutdown process appears to be stalled due to busy or blocked plugins.
Check the logs for more information. {:level=>:error}
{"inflight_count"=>125, "stalling_thread_info"=>{["LogStash::Filters::Ruby",
{"code"=>"sleep 10000"}]=>[{"thread_id"=>19, "name"=>"[main]>worker0",
"current_call"=>"(ruby filter code):1:in `sleep'"}]}} {:level=>:warn}
{"inflight_count"=>125, "stalling_thread_info"=>{["LogStash::Filters::Ruby",
{"code"=>"sleep 10000"}]=>[{"thread_id"=>19, "name"=>"[main]>worker0",
"current_call"=>"(ruby filter code):1:in `sleep'"}]}} {:level=>:warn}
Forcefully quitting logstash.. {:level=>:fatal}
```

::::


When `--pipeline.unsafe_shutdown` isn’t enabled, Logstash continues to run and produce these reports periodically.


