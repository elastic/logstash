---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/ls-to-ls-native.html
---

# Logstash-to-Logstash: Output to Input [ls-to-ls-native]

The Logstash output to Logstash input is the default approach for Logstash-to-Logstash communication.

::::{note}
Check out these [considerations](/reference/logstash-to-logstash-communications.md#native-considerations) before you implement {{ls}}-to-{{ls}}.
::::


## Configuration overview [overview-ls-ls]

To connect two Logstash instances:

1. Configure the downstream (server) Logstash to use Logstash input
2. Configure the upstream (client) Logstash to use Logstash output
3. Secure the communication between Logstash input and Logstash output

### Configure the downstream Logstash to use Logstash input [configure-downstream-logstash-input]

Configure the Logstash input on the downstream (receiving) Logstash to receive connections. The minimum configuration requires this option:

* `port` - To set a custom port. The default is 9800 if none is provided.

```json
input {
    logstash {
        port => 9800
    }
}
```


### Configure the upstream Logstash to use Logstash output [configure-upstream-logstash-output]

In order to obtain the best performance when sending data from one Logstash to another, the data is batched and compressed. As such, the upstream Logstash (the sending Logstash) only needs to be concerned about configuring the receiving endpoint with these options:

* `hosts` - The receiving one or more Logstash host and port pairs. If no port specified, 9800 will be used.

::::{note}
{{ls}} load balances batched events to *all* of its configured downstream hosts. Any failures caused by network issues, back-pressure or other conditions, will result in the downstream host being isolated from load balancing for at least 60 seconds.
::::


```json
output {
    logstash {
        hosts => ["10.0.0.123", "10.0.1.123:9800"]
    }
}
```


### Secure Logstash to Logstash [securing-logstash-to-logstash]

It is important that you secure the communication between Logstash instances. Use SSL/TLS mutual authentication in order to ensure that the upstream Logstash instance sends encrypted data to a trusted downstream Logstash instance, and vice versa.

1. Create a certificate authority (CA) in order to sign the certificates that you plan to use between Logstash instances. Creating a correct SSL/TLS infrastructure is outside the scope of this document.

    ::::{tip}
    We recommend you use the [elasticsearch-certutil](elasticsearch://reference/elasticsearch/command-line-tools/certutil.md) tool to generate your certificates.
    ::::

2. Configure the downstream (receiving) Logstash to use SSL. Add these settings to the Logstash input configuration:

    * `ssl_enabled`: When set to `true`, it enables Logstash use of SSL/TLS
    * `ssl_key`: Specifies the key that Logstash uses to authenticate with the client.
    * `ssl_certificate`: Specifies the certificate that Logstash uses to authenticate with the client.
    * `ssl_certificate_authorities`: Configures Logstash to trust any certificates signed by the specified CA.
    * `ssl_client_authentication`: Specifies whether Logstash server verifies the client certificate against the CA.

    For example:

    ```json
    input {
      logstash {
        ...

        ssl_enabled => true
        ssl_key => "server.pkcs8.key"
        ssl_certificate => "server.crt"
        ssl_certificate_authorities => "ca.crt"
        ssl_client_authentication => required
      }
    }
    ```

3. Configure the upstream (sending) Logstash to use SSL. Add these settings to the Logstash output configuration:

    * `ssl_key`: Specifies the key the Logstash client uses to authenticate with the Logstash server.
    * `ssl_certificate`: Specifies the certificate that the Logstash client uses to authenticate to the Logstash server.
    * `ssl_certificate_authorities`: Configures the Logstash client to trust any certificates signed by the specified CA.

    For example:

    ```json
    output {
      logstash {
        ...

        ssl_enabled => true
        ssl_key => "client.pkcs8.key"
        ssl_certificate => "client.crt"
        ssl_certificate_authorities => "ca.crt"
      }
    }
    ```

4. If you would like an additional authentication step, you can also use basic user/password authentication in both Logstash instances:

    * `username`: Sets the username to use for authentication.
    * `password`: Sets the password to use for authentication.

    For example, you would need to add the following to both Logstash instances:

    ```json
    ...
      logstash {
        ...

        username => "your-user"
        password => "your-secret"
      }
    ...
    ```




