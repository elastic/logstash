# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

module LogStash module Helpers
  module ElasticsearchOptions
    extend self

    ES_SETTINGS = %w(
      ssl.certificate_authority
      ssl.ca_trusted_fingerprint
      ssl.truststore.path
      ssl.keystore.path
      hosts
      username
      password
      cloud_id
      cloud_auth
      api_key
      proxy
    )

    # xpack setting to ES output setting
    SETTINGS_MAPPINGS = {
      "cloud_id" => "cloud_id",
      "cloud_auth" => "cloud_auth",
      "username" => "user",
      "password" => "password",
      "api_key" => "api_key",
      "proxy" => "proxy",
      "sniffing" => "sniffing",
      "ssl.certificate_authority" => "ssl_certificate_authorities",
      "ssl.cipher_suites" => "ssl_cipher_suites",
      "ssl.ca_trusted_fingerprint" => "ca_trusted_fingerprint",
      "ssl.truststore.path" => "ssl_truststore_path",
      "ssl.truststore.password" => "ssl_truststore_password",
      "ssl.keystore.path" => "ssl_keystore_path",
      "ssl.keystore.password" => "ssl_keystore_password",
      "ssl.certificate" => "ssl_certificate",
      "ssl.key" => "ssl_key",
    }

    # Populate the Elasticsearch options from LogStashSettings file, based on the feature that is being used.
    # @return Hash
    def es_options_from_settings(feature, settings)
      prefix = (feature == "monitoring" && LogStash::MonitoringExtension.use_direct_shipping?(settings)) ? "" : "xpack."
      opts = {}

      validate_authentication!(feature, settings, prefix)

      # transpose all directly mappable settings
      SETTINGS_MAPPINGS.each do |xpack_setting, es_setting|
        v = settings.get("#{prefix}#{feature}.elasticsearch.#{xpack_setting}")
        opts[es_setting] = v unless v.nil?
      end

      # avoid passing an empty array to the plugin configuration
      if opts['ssl_cipher_suites']&.empty?
        opts.delete('ssl_cipher_suites')
      end

      # process remaining settings

      unless settings.get("#{prefix}#{feature}.elasticsearch.cloud_id")
        opts['hosts'] = settings.get("#{prefix}#{feature}.elasticsearch.hosts")
      end

      # The `certificate` mode is currently not supported by the ES output plugin. This value was used by Logstash to set the
      # deprecated `ssl_certificate_verification` boolean option. To keep it backward compatible with the x-pack settings,
      # it fallbacks any value different of `none` to `full` so the behaviour stills the same.
      if settings.get("#{prefix}#{feature}.elasticsearch.ssl.verification_mode") == "none"
        opts['ssl_verification_mode'] = "none"
      else
        opts['ssl_verification_mode'] = "full"
      end

      # if all hosts are using https or any of the ssl related settings are set
      if ssl?(feature, settings, prefix)
        opts['ssl_enabled'] = true
      end

      # the username setting has a default value and should not be included when using another authentication such as cloud_auth or api_key.
      # it should also not be included when no password is set.
      # it is safe to silently remove here since all authentication verifications have been validated at this point.
      if settings.set?("#{prefix}#{feature}.elasticsearch.cloud_auth") ||
         settings.set?("#{prefix}#{feature}.elasticsearch.api_key") ||
         (!settings.set?("#{prefix}#{feature}.elasticsearch.password") && !settings.set?("#{prefix}#{feature}.elasticsearch.username"))
        opts.delete('user')
      end

      opts
    end

    # when the Elasticsearch Output client is used exclusively to
    # perform Logstash-defined actions without user input, adding
    # a product origin header allows us to reduce log noise.
    def es_options_with_product_origin_header(es_options)
      custom_headers = es_options.delete('custom_headers') { Hash.new }
                                 .merge('x-elastic-product-origin' => 'logstash')

      es_options.merge('custom_headers' => custom_headers)
    end

    def ssl?(feature, settings, prefix)
      return true if verify_https_scheme(feature, settings, prefix)
      return true if settings.set?("#{prefix}#{feature}.elasticsearch.cloud_id") # cloud_id always resolves to https hosts
      return true if settings.set?("#{prefix}#{feature}.elasticsearch.ssl.certificate_authority")
      return true if settings.set?("#{prefix}#{feature}.elasticsearch.ssl.ca_trusted_fingerprint")
      return true if settings.set?("#{prefix}#{feature}.elasticsearch.ssl.cipher_suites") && settings.get("#{prefix}#{feature}.elasticsearch.ssl.cipher_suites")&.any?
      return true if settings.set?("#{prefix}#{feature}.elasticsearch.ssl.truststore.path") && settings.set?("#{prefix}#{feature}.elasticsearch.ssl.truststore.password")
      return true if settings.set?("#{prefix}#{feature}.elasticsearch.ssl.keystore.path") && settings.set?("#{prefix}#{feature}.elasticsearch.ssl.keystore.password")
      return true if settings.set?("#{prefix}#{feature}.elasticsearch.ssl.certificate") && settings.set?("#{prefix}#{feature}.elasticsearch.ssl.key")

      return false
    end

    HTTPS_SCHEME = /^https:\/\/.+/
    def verify_https_scheme(feature, settings, prefix)
      hosts = Array(settings.get("#{prefix}#{feature}.elasticsearch.hosts"))
      hosts.all? {|host| host.match?(HTTPS_SCHEME)}
    end

    # If no settings are configured, then assume that the feature has not been configured.
    def feature_configured?(feature, settings)
      ES_SETTINGS.each do |option|
        return true if settings.set?("xpack.#{feature}.elasticsearch.#{option}")
      end
      false
    end

    private

    def validate_authentication!(feature, settings, prefix)
      provided_cloud_id = settings.set?("#{prefix}#{feature}.elasticsearch.cloud_id")
      provided_hosts = settings.set?("#{prefix}#{feature}.elasticsearch.hosts")
      provided_cloud_auth = settings.set?("#{prefix}#{feature}.elasticsearch.cloud_auth")
      provided_api_key = settings.set?("#{prefix}#{feature}.elasticsearch.api_key")
      provided_username = settings.set?("#{prefix}#{feature}.elasticsearch.username")
      provided_password = settings.set?("#{prefix}#{feature}.elasticsearch.password")

      # note that the username setting has a default value and in the verifications below
      # we can test on the password option being set as a proxy to using basic auth because
      # if the username is not explicitly set it will use its default value.

      if provided_cloud_auth && (provided_username || provided_password)
        raise ArgumentError.new(
          "Both #{prefix}#{feature}.elasticsearch.cloud_auth and " +
          "#{prefix}#{feature}.elasticsearch.username/password " +
          "specified, please only use one of those"
        )
      end

      if provided_username && !provided_password
        raise(ArgumentError,
          "When using #{prefix}#{feature}.elasticsearch.username, " +
          "#{prefix}#{feature}.elasticsearch.password must also be set"
        )
      end

      if provided_cloud_id
        if provided_hosts
          raise(ArgumentError,
            "Both #{prefix}#{feature}.elasticsearch.cloud_id and " +
            "#{prefix}#{feature}.elasticsearch.hosts specified, please only use one of those"
          )
        end
      end

      authentication_count = 0
      authentication_count += 1 if provided_cloud_auth
      authentication_count += 1 if provided_password
      authentication_count += 1 if provided_api_key

      if authentication_count > 1
        raise(ArgumentError, "Multiple authentication options are specified, please only use one of #{prefix}#{feature}.elasticsearch.username/password, #{prefix}#{feature}.elasticsearch.cloud_auth or #{prefix}#{feature}.elasticsearch.api_key")
      end

      if provided_api_key && !ssl?(feature, settings, prefix)
        raise(ArgumentError, "Using api_key authentication requires SSL/TLS secured communication")
      end
    end
  end end end
