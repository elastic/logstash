---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/ls-to-ls-lumberjack.html
---

# Logstash-to-Logstash: Lumberjack output to Beats input [ls-to-ls-lumberjack]

You can set up communication between two Logstash machines by connecting the Lumberjack output to the Beats input.

Logstash-to-Logstash using Lumberjack and Beats has been our standard approach for {{ls}}-to-{{ls}}, and may still be the best option for more robust use cases.

::::{note}
Check out these [considerations](/reference/logstash-to-logstash-communications.md#lumberjack-considerations) before you implement Logstash-to-Logstash using Lumberjack and Beats.
::::


## Configuration overview [_configuration_overview]

Use the Lumberjack protocol to connect two Logstash machines.

1. Generate a trusted SSL certificate (required by the lumberjack protocol).
2. Copy the SSL certificate to the upstream Logstash machine.
3. Copy the SSL certificate and key to the downstream Logstash machine.
4. Set the upstream Logstash machine to use the Lumberjack output to send data.
5. Set the downstream Logstash machine to listen for incoming Lumberjack connections through the Beats input.
6. Test it.

### Generate a self-signed SSL certificate and key [generate-self-signed-cert]

Use the `openssl req` command to generate a self-signed certificate and key. The `openssl req` command is available with some operating systems. You may need to install the openssl command line program for others.

Run the following command:

```shell
openssl req -x509 -batch -nodes -newkey rsa:2048 -keyout lumberjack.key -out lumberjack.cert -subj /CN=localhost
```

where:

* `lumberjack.key` is the name of the SSL key to be created
* `lumberjack.cert` is the name of the SSL certificate to be created
* `localhost` is the name of the upstream Logstash computer

This command produces output similar to the following:

```shell
Generating a 2048 bit RSA private key
.................................+++
....................+++
writing new private key to 'lumberjack.key'
```


### Copy the SSL certificate and key [copy-cert-key]

Copy the SSL certificate to the upstream Logstash machine.

Copy the SSL certificate and key to the downstream Logstash machine.


### Start the upstream Logstash instance [save-cert-ls1]

Start Logstash and generate test events:

```shell
bin/logstash -e 'input { generator { count => 5 } } output { lumberjack { codec => json hosts => "mydownstreamhost" ssl_certificate => "lumberjack.cert" port => 5000 } }'
```

This sample command sends five events to mydownstreamhost:5000 using the SSL certificate provided.


### Start the downstream Logstash instance [save-cert-ls2]

Start the downstream instance of Logstash:

```shell
bin/logstash -e 'input { beats { codec => json port => 5000 ssl_enabled => true ssl_certificate => "lumberjack.cert" ssl_key => "lumberjack.key"} }'
```

This sample command sets port 5000 to listen for incoming Beats input.


### Verify the communication [test-ls-to-ls]

Watch the downstream Logstash machine for the incoming events. You should see five incrementing events similar to the following:

```shell
{
  "@timestamp" => 2018-02-07T12:16:39.415Z,
  "sequence"   => 0
  "tags"       => [
    [0] "beats_input_codec_json_applied"
  ],
  "message"    => "Hello world",
  "@version"   => "1",
  "host"       => "ls1.semicomplete.com"
}
```

If you see all five events with consistent fields and formatting, incrementing by one, then your configuration is correct.



