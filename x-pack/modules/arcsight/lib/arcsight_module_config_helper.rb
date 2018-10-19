# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require 'logstash/namespace'

module LogStash
  module Arcsight
    module Confighelper
      extend self
      def kafka_input_ssl_sasl_config
        security_protocol = setting("var.input.kafka.security_protocol", "unset")
        return "" if security_protocol == "unset"
        lines = ["security_protocol => '#{security_protocol}'"]
        lines.push("ssl_truststore_type => '#{setting("var.input.kafka.ssl_truststore_type", "")}'")

        ssl_truststore_location = setting("var.input.kafka.ssl_truststore_location", "")
        lines.push("ssl_truststore_location => '#{ssl_truststore_location}'") unless ssl_truststore_location.empty?

        lines.push("ssl_truststore_password => '#{setting("var.input.kafka.ssl_truststore_password", "")}'")
        lines.push("ssl_keystore_type => '#{setting("var.input.kafka.ssl_keystore_type", "")}'")

        ssl_keystore_location = setting("var.input.kafka.ssl_keystore_location", "")
        lines.push("ssl_keystore_location => '#{ssl_keystore_location}'") unless ssl_keystore_location.empty?

        lines.push("ssl_keystore_password => '#{setting("var.input.kafka.ssl_keystore_password", "")}'")
        lines.push("ssl_key_password => '#{setting("var.input.kafka.ssl_key_password", "")}'")

        lines.push("sasl_mechanism => '#{setting("var.input.kafka.sasl_mechanism", "")}'")
        lines.push("sasl_kerberos_service_name => '#{setting("var.input.kafka.sasl_kerberos_service_name", "")}'")

        jaas_path = setting("var.input.kafka.jaas_path", "")
        lines.push("jaas_path => '#{jaas_path}'") unless jaas_path.empty?

        kerberos_config = setting("var.input.kafka.kerberos_config", "")
        lines.push("kerberos_config => '#{kerberos_config}'") unless kerberos_config.empty?

        lines.compact.join("\n    ")
      end

      def tcp_input_ssl_config
        ssl_enabled = setting("var.input.tcp.ssl_enable", false)
        return "" if ssl_enabled == "false"
        lines = ["ssl_enable => true"]

        verify_enabled = setting("var.input.tcp.ssl_verify", true)
        lines.push("ssl_verify => #{verify_enabled}")

        ssl_cert = setting("var.input.tcp.ssl_cert", "")
        lines.push("ssl_cert => '#{ssl_cert}'") unless ssl_cert.empty?

        ssl_key = setting("var.input.tcp.ssl_key", "")
        lines.push("ssl_key => '#{ssl_key}'") unless ssl_key.empty

        lines.push("ssl_key_passphrase => '#{ setting("var.input.tcp.ssl_key_passphrase", "")}'")

        certs_array_as_string = array_to_string(
          get_setting(LogStash::Setting::SplittableStringArray.new("var.input.tcp.ssl_extra_chain_certs", String, []))
        )
        lines.push("ssl_extra_chain_certs => #{certs_array_as_string}")

        lines.compact.join("\n    ")
      end
    end
  end
end
