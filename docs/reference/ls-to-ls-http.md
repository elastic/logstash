---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/ls-to-ls-http.html
---

# Logstash-to-Logstash: HTTP output to HTTP input [ls-to-ls-http]

HTTP output to HTTP input is an alternative to the Lumberjack output to Beats input approach for Logstash-to-Logstash communication. This approach relies on the use of [http output](logstash-docs-md://lsr/plugins-outputs-http.md) to [http input](logstash-docs-md://lsr/plugins-inputs-http.md) plugins.

::::{note}
{{ls}}-to-{{ls}} using HTTP input/output plugins is now being deprecated in favor of [Logstash-to-Logstash: Output to Input](/reference/ls-to-ls-native.md).
::::


## Configuration overview [overview-http-http]

To use the HTTP protocol to connect two Logstash instances:

1. Configure the downstream (server) Logstash to use HTTP input
2. Configure the upstream (client) Logstash to use HTTP output
3. Secure the communication between HTTP input and HTTP output

### Configure the downstream Logstash to use HTTP input [configure-downstream-logstash-http-input]

Configure the HTTP input on the downstream (receiving) Logstash to receive connections. The minimum configuration requires these options:

* `port` - To set a custom port.
* `additional_codecs` - To set `application/json` to be `json_lines`.

```json
input {
    http {
        port => 8080
        additional_codecs => { "application/json" => "json_lines" }
    }
}
```


### Configure the upstream Logstash to use HTTP output [configure-upstream-logstash-http-output]

In order to obtain the best performance when sending data from one Logstash to another, the data needs to be batched and compressed. As such, the upstream Logstash (the sending Logstash) needs to be configured with these options:

* `url` - The receiving Logstash.
* `http_method` - Set to `post`.
* `retry_non_idempotent` - Set to `true`, in order to retry failed events.
* `format` - Set to `json_batch` to batch the data.
* `http_compression` - Set to `true` to ensure the data is compressed.

```json
output {
    http {
        url => '<protocol>://<downstream-logstash>:<port>'
        http_method => post
        retry_non_idempotent => true
        format => json_batch
        http_compression => true
    }
}
```


### Secure Logstash to Logstash [securing-logstash-to-logstash-http]

It is important that you secure the communication between Logstash instances. Use SSL/TLS mutual authentication in order to ensure that the upstream Logstash instance sends encrypted data to a trusted downstream Logstash instance, and vice versa.

1. Create a certificate authority (CA) in order to sign the certificates that you plan to use between Logstash instances. Creating a correct SSL/TLS infrastructure is outside the scope of this document.

    ::::{tip}
    We recommend you use the [elasticsearch-certutil](elasticsearch://reference/elasticsearch/command-line-tools/certutil.md) tool to generate your certificates.
    ::::

2. Configure the downstream (receiving) Logstash to use SSL. Add these settings to the HTTP Input configuration:

    * `ssl`: When set to `true`, it enables Logstash use of SSL/TLS
    * `ssl_key`: Specifies the key that Logstash uses to authenticate with the client.
    * `ssl_certificate`: Specifies the certificate that Logstash uses to authenticate with the client.
    * `ssl_certificate_authorities`: Configures Logstash to trust any certificates signed by the specified CA.
    * `ssl_verify_mode`:  Specifies whether Logstash server verifies the client certificate against the CA.

    For example:

    ```json
    input {
      http {
        ...

        ssl => true
        ssl_key => "server.key.pk8"
        ssl_certificate => "server.crt"
        ssl_certificate_authorities => "ca.crt"
        ssl_verify_mode => force_peer
      }
    }
    ```

3. Configure the upstream (sending) Logstash to use SSL. Add these settings to the HTTP output configuration:

    * `ssl_certificate_authorities`: Configures the Logstash client to trust any certificates signed by the specified CA.
    * `ssl_key`: Specifies the key the Logstash client uses to authenticate with the Logstash server.
    * `ssl_certification`: Specifies the certificate that the Logstash client uses to authenticate to the Logstash server.

    For example:

    ```json
    output {
      http {
        ...

        ssl_certificate_authorities => "ca.crt"
        ssl_key => "client.key.pk8"
        ssl_certificate => "client.crt"
      }
    }
    ```

4. If you would like an additional authentication step, you can also use basic user/password authentication in both Logstash instances:

    * `user`: Sets the username to use for authentication.
    * `password`: Sets the password to use for authentication.

    For example, you would need to add the following to both Logstash instances:

    ```json
    ...
      http {
        ...

        user => "your-user"
        password => "your-secret"
      }
    ...
    ```




