---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/use-filebeat-modules-kafka.html
---

# Example: Set up Filebeat modules to work with Kafka and Logstash [use-filebeat-modules-kafka]

This section shows how to set up {{filebeat}} [modules](beats://docs/reference/filebeat/filebeat-modules-overview.md) to work with {{ls}} when you are using Kafka in between {{filebeat}} and {{ls}} in your publishing pipeline. The main goal of this example is to show how to load ingest pipelines from {{filebeat}} and use them with {{ls}}.

The examples in this section show simple configurations with topic names hard coded. For a full list of configuration options, see documentation about configuring the [Kafka input plugin](/reference/plugins-inputs-kafka.md). Also see [Configure the Kafka output](beats://docs/reference/filebeat/kafka-output.md) in the *{{filebeat}} Reference*.

## Set up and run {{filebeat}} [_set_up_and_run_filebeat]

1. If you haven’t already set up the {{filebeat}} index template and sample {{kib}} dashboards, run the {{filebeat}} `setup` command to do that now:

    ```shell
    filebeat -e setup
    ```

    The `-e` flag is optional and sends output to standard error instead of syslog.

    A connection to {{es}} and {{kib}} is required for this one-time setup step because {{filebeat}} needs to create the index template in {{es}} and load the sample dashboards into {{kib}}. For more information about configuring the connection to {{es}}, see the Filebeat [quick start](beats://docs/reference/filebeat/filebeat-installation-configuration.md).

    After the template and dashboards are loaded, you’ll see the message `INFO {{kib}} dashboards successfully loaded. Loaded dashboards`.

2. Run the `modules enable` command to enable the modules that you want to run. For example:

    ```shell
    filebeat modules enable system
    ```

    You can further configure the module by editing the config file under the {{filebeat}} `modules.d` directory. For example, if the log files are not in the location expected by the module, you can set the `var.paths` option.

    ::::{note}
    You must enable at least one fileset in the module. **Filesets are disabled by default.**
    ::::

3. Run the `setup` command with the `--pipelines` and `--modules` options specified to load ingest pipelines for the modules you’ve enabled. This step also requires a connection to {{es}}. If you want use a {{ls}} pipeline instead of ingest node to parse the data, skip this step.

    ```shell
    filebeat setup --pipelines --modules system
    ```

4. Configure {{filebeat}} to send log lines to Kafka. To do this, in the `filebeat.yml` config file, disable the {{es}} output by commenting it out, and enable the Kafka output. For example:

    ```yaml
    #output.elasticsearch:
      #hosts: ["localhost:9200"]
    output.kafka:
      hosts: ["kafka:9092"]
      topic: "filebeat"
      codec.json:
        pretty: false
    ```

5. Start {{filebeat}}. For example:

    ```shell
    filebeat -e
    ```

    {{filebeat}} will attempt to send messages to {{ls}} and continue until {{ls}} is available to receive them.

    ::::{note}
    Depending on how you’ve installed {{filebeat}}, you might see errors related to file ownership or permissions when you try to run {{filebeat}} modules. See [Config File Ownership and Permissions](beats://docs/reference/libbeat/config-file-permissions.md) in the *Beats Platform Reference* if you encounter errors related to file ownership or permissions.
    ::::



## Create and start the {{ls}} pipeline [_create_and_start_the_ls_pipeline]

1. On the system where {{ls}} is installed, create a {{ls}} pipeline configuration that reads from a Kafka input and sends events to an {{es}} output:

    ```yaml
    input {
      kafka {
        bootstrap_servers => "myhost:9092"
        topics => ["filebeat"]
        codec => json
      }
    }

    output {
      if [@metadata][pipeline] {
        elasticsearch {
          hosts => "https://myEShost:9200"
          manage_template => false
          index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
          pipeline => "%{[@metadata][pipeline]}" <1>
          user => "elastic"
          password => "secret"
        }
      } else {
        elasticsearch {
          hosts => "https://myEShost:9200"
          manage_template => false
          index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
          user => "elastic"
          password => "secret"
        }
      }
    }
    ```

    1. Set the `pipeline` option to `%{[@metadata][pipeline]}`. This setting configures {{ls}} to select the correct ingest pipeline based on metadata passed in the event.

2. Start {{ls}}, passing in the pipeline configuration file you just defined. For example:

    ```shell
    bin/logstash -f mypipeline.conf
    ```

    {{ls}} should start a pipeline and begin receiving events from the Kafka input.



## Visualize the data [_visualize_the_data]

To visualize the data in {{kib}}, launch the {{kib}} web interface by pointing your browser to port 5601. For example, [http://127.0.0.1:5601](http://127.0.0.1:5601). Click **Dashboards** then view the {{filebeat}} dashboards.
