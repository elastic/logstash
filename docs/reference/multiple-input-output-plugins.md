---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/multiple-input-output-plugins.html
---

# Stitching Together Multiple Input and Output Plugins [multiple-input-output-plugins]

The information you need to manage often comes from several disparate sources, and use cases can require multiple destinations for your data. Your Logstash pipeline can use multiple input and output plugins to handle these requirements.

In this section, you create a Logstash pipeline that takes input from a Twitter feed and the Filebeat client, then sends the information to an Elasticsearch cluster as well as writing the information directly to a file.


## Reading from a Twitter Feed [twitter-configuration]

To add a Twitter feed, you use the [`twitter`](/reference/plugins-inputs-twitter.md) input plugin. To configure the plugin, you need several pieces of information:

* A *consumer key*, which uniquely identifies your Twitter app.
* A *consumer secret*, which serves as the password for your Twitter app.
* One or more *keywords* to search in the incoming feed. The example shows using "cloud" as a keyword, but you can use whatever you want.
* An *oauth token*, which identifies the Twitter account using this app.
* An *oauth token secret*, which serves as the password of the Twitter account.

Visit [https://dev.twitter.com/apps](https://dev.twitter.com/apps) to set up a Twitter account and generate your consumer key and secret, as well as your access token and secret. See the docs for the [`twitter`](/reference/plugins-inputs-twitter.md) input plugin if you’re not sure how to generate these keys.

Like you did earlier when you worked on [Parsing Logs with Logstash](/reference/advanced-pipeline.md), create a config file (called `second-pipeline.conf`) that contains the skeleton of a configuration pipeline. If you want, you can reuse the file you created earlier, but make sure you pass in the correct config file name when you run Logstash.

Add the following lines to the `input` section of the `second-pipeline.conf` file, substituting your values for the placeholder values shown here:

```json
    twitter {
        consumer_key => "enter_your_consumer_key_here"
        consumer_secret => "enter_your_secret_here"
        keywords => ["cloud"]
        oauth_token => "enter_your_access_token_here"
        oauth_token_secret => "enter_your_access_token_secret_here"
    }
```


## Configuring Filebeat to Send Log Lines to Logstash [configuring-lsf]

As you learned earlier in [Configuring Filebeat to Send Log Lines to Logstash](/reference/advanced-pipeline.md#configuring-filebeat), the [Filebeat](https://github.com/elastic/beats/tree/main/filebeat) client is a lightweight, resource-friendly tool that collects logs from files on the server and forwards these logs to your Logstash instance for processing.

After installing Filebeat, you need to configure it. Open the `filebeat.yml` file located in your Filebeat installation directory, and replace the contents with the following lines. Make sure `paths` points to your syslog:

```shell
filebeat.inputs:
- type: log
  paths:
    - /var/log/*.log <1>
  fields:
    type: syslog <2>
output.logstash:
  hosts: ["localhost:5044"]
```

1. Absolute path to the file or files that Filebeat processes.
2. Adds a field called `type` with the value `syslog` to the event.


Save your changes.

To keep the configuration simple, you won’t specify TLS/SSL settings as you would in a real world scenario.

Configure your Logstash instance to use the Filebeat input plugin by adding the following lines to the `input` section of the `second-pipeline.conf` file:

```json
    beats {
        port => "5044"
    }
```


## Writing Logstash Data to a File [logstash-file-output]

You can configure your Logstash pipeline to write data directly to a file with the [`file`](/reference/plugins-outputs-file.md) output plugin.

Configure your Logstash instance to use the `file` output plugin by adding the following lines to the `output` section of the `second-pipeline.conf` file:

```json
    file {
        path => "/path/to/target/file"
    }
```


## Writing to Multiple Elasticsearch Nodes [multiple-es-nodes]

Writing to multiple Elasticsearch nodes lightens the resource demands on a given Elasticsearch node, as well as providing redundant points of entry into the cluster when a particular node is unavailable.

To configure your Logstash instance to write to multiple Elasticsearch nodes, edit the `output` section of the `second-pipeline.conf` file to read:

```json
output {
    elasticsearch {
        hosts => ["IP Address 1:port1", "IP Address 2:port2", "IP Address 3"]
    }
}
```

Use the IP addresses of three non-master nodes in your Elasticsearch cluster in the host line. When the `hosts` parameter lists multiple IP addresses, Logstash load-balances requests across the list of addresses. Also note that the default port for Elasticsearch is `9200` and can be omitted in the configuration above.


### Testing the Pipeline [testing-second-pipeline]

At this point, your `second-pipeline.conf` file looks like this:

```json
input {
    twitter {
        consumer_key => "enter_your_consumer_key_here"
        consumer_secret => "enter_your_secret_here"
        keywords => ["cloud"]
        oauth_token => "enter_your_access_token_here"
        oauth_token_secret => "enter_your_access_token_secret_here"
    }
    beats {
        port => "5044"
    }
}
output {
    elasticsearch {
        hosts => ["IP Address 1:port1", "IP Address 2:port2", "IP Address 3"]
    }
    file {
        path => "/path/to/target/file"
    }
}
```

Logstash is consuming data from the Twitter feed you configured, receiving data from Filebeat, and indexing this information to three nodes in an Elasticsearch cluster as well as writing to a file.

At the data source machine, run Filebeat with the following command:

```shell
sudo ./filebeat -e -c filebeat.yml -d "publish"
```

Filebeat will attempt to connect on port 5044. Until Logstash starts with an active Beats plugin, there won’t be any answer on that port, so any messages you see regarding failure to connect on that port are normal for now.

To verify your configuration, run the following command:

```shell
bin/logstash -f second-pipeline.conf --config.test_and_exit
```

The `--config.test_and_exit` option parses your configuration file and reports any errors. When the configuration file passes the configuration test, start Logstash with the following command:

```shell
bin/logstash -f second-pipeline.conf
```

Use the `grep` utility to search in the target file to verify that information is present:

```shell
grep syslog /path/to/target/file
```

Run an Elasticsearch query to find the same information in the Elasticsearch cluster:

```shell
curl -XGET 'localhost:9200/logstash-$DATE/_search?pretty&q=fields.type:syslog'
```

Replace $DATE with the current date, in YYYY.MM.DD format.

To see data from the Twitter feed, try this query:

```shell
curl -XGET 'http://localhost:9200/logstash-$DATE/_search?pretty&q=client:iphone'
```

Again, remember to replace $DATE with the current date, in YYYY.MM.DD format.

