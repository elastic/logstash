# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

module LogStash module Helpers
  module ElasticsearchOptions
    extend self

    ES_SETTINGS =%w(
        ssl.certificate_authority
        ssl.truststore.path
        ssl.keystore.path
        hosts
        username
        password
        cloud_id
        cloud_auth
        proxy
      )

    # Retrieve elasticsearch options from either specific settings, or modules if the setting is not there and the
    # feature supports falling back to modules if the feature is not specified in logstash.yml
    def es_options_from_settings_or_modules(feature, settings)
      only_modules_configured?(feature, settings) ? es_options_from_modules(settings) : es_options_from_settings(feature, settings)
    end

    # Populate the Elasticsearch options from LogStashSettings file, based on the feature that is being used.
    # @return Hash
    def es_options_from_settings(feature, settings)
      prefix = if feature == "monitoring" &&
                    LogStash::MonitoringExtension.use_direct_shipping?(settings)
                 ""
               else
                 "xpack."
               end
      opts = {}

      if cloud_id = settings.get("#{prefix}#{feature}.elasticsearch.cloud_id")
        opts['cloud_id'] = cloud_id
        check_cloud_id_configuration!(feature, settings, prefix)
      else
        opts['hosts'] = settings.get("#{prefix}#{feature}.elasticsearch.hosts")
      end
      if cloud_auth = settings.get("#{prefix}#{feature}.elasticsearch.cloud_auth")
        opts['cloud_auth'] = cloud_auth
        check_cloud_auth_configuration!(feature, settings, prefix)
      else
        opts['user'] = settings.get("#{prefix}#{feature}.elasticsearch.username")
        opts['password'] = settings.get("#{prefix}#{feature}.elasticsearch.password")
      end
      if proxysetting = settings.get("#{prefix}#{feature}.elasticsearch.proxy")
        opts['proxy'] = proxysetting
      end

      opts['sniffing'] = settings.get("#{prefix}#{feature}.elasticsearch.sniffing")
      opts['ssl_certificate_verification'] = settings.get("#{prefix}#{feature}.elasticsearch.ssl.verification_mode") == 'certificate'

      if cacert = settings.get("#{prefix}#{feature}.elasticsearch.ssl.certificate_authority")
        opts['cacert'] = cacert
        opts['ssl'] = true
      end

      if truststore = settings.get("#{prefix}#{feature}.elasticsearch.ssl.truststore.path")
        opts['truststore'] = truststore
        opts['truststore_password'] = settings.get("#{prefix}#{feature}.elasticsearch.ssl.truststore.password")
        opts['ssl'] = true
      end

      if keystore = settings.get("#{prefix}#{feature}.elasticsearch.ssl.keystore.path")
        opts['keystore'] = keystore
        opts['keystore_password']= settings.get("#{prefix}#{feature}.elasticsearch.ssl.keystore.password")
        opts['ssl'] = true
      end
      opts
    end


    # Elasticsearch settings can be extracted from the modules settings inside the configuration.
    # Few options will be supported, however - the modules security configuration is
    # different to
    def es_options_from_modules(settings)
      module_settings = extract_module_settings(settings)

      if module_settings.empty?
        return nil
      end

      opts = {}

      setting = LogStash::Setting::SplittableStringArray.new("var.elasticsearch.hosts", String, ["localhost:9200"])
      raw_value = module_settings[setting.name]
      setting.set(raw_value) unless raw_value.nil?
      opts['hosts'] = setting.value
      opts['user'] = module_settings['var.elasticsearch.username']
      password = module_settings['var.elasticsearch.password']
      opts['password'] = password.value unless password.nil?

      # Sniffing is not supported for modules.
      opts['sniffing'] = false
      if cacert = module_settings["var.elasticsearch.ssl.certificate_authority"]
        opts['cacert'] = cacert
        opts['ssl'] = true
      end
      opts
    end


    # Determine whether only modules have been configured, and not monitoring
    # @param String feature to be checked
    # @param Logstash::Settings Logstash settings
    def only_modules_configured?(feature, settings)
      modules_configured?(settings) && !feature_configured?(feature, settings)
    end

    # If no settings are configured, then assume that the feature has not been configured.
    # The assumption is that with security setup, at least one setting (password or certificates)
    # should be configured. If security is not setup, and defaults 'just work' for monitoring, then
    # this will need to be reconsidered.
    def feature_configured?(feature, settings)
      ES_SETTINGS.each do |option|
        return true if settings.set?("xpack.#{feature}.elasticsearch.#{option}")
      end
      false
    end

    def modules_configured?(settings)
      !extract_module_settings(settings).nil?
    end

    # Read module settings from yaml file. This should be refactored in Logstash proper to allow for DRY-ing up
    # these settings
    def extract_module_settings(settings)
      cli_settings = settings.get("modules.cli")
      yml_settings = settings.get("modules")
      modules_array = if !(cli_settings.empty? && yml_settings.empty?)
                        LogStash::Modules::SettingsMerger.merge(cli_settings, yml_settings)
                      elsif cli_settings.empty?
                        yml_settings
                      else
                        cli_settings
                      end
      LogStash::Modules::SettingsMerger.merge_cloud_settings(modules_array.first, settings) unless modules_array.empty?
      # As only one module is supported in the initial rollout, use the first one found
      modules_array.first
    end

    private

    def check_cloud_id_configuration!(feature, settings, prefix)
      return if !settings.set?("#{prefix}#{feature}.elasticsearch.hosts")

      raise ArgumentError.new("Both \"#{prefix}#{feature}.elasticsearch.cloud_id\" and " +
                              "\"#{prefix}#{feature}.elasticsearch.hosts\" specified, please only use one of those.")
    end

    def check_cloud_auth_configuration!(feature, settings, prefix)
      return if !settings.set?("#{prefix}#{feature}.elasticsearch.username") &&
                !settings.set?("#{prefix}#{feature}.elasticsearch.password")

      raise ArgumentError.new("Both \"#{prefix}#{feature}.elasticsearch.cloud_auth\" and " +
                              "\"#{prefix}#{feature}.elasticsearch.username\"/\"#{prefix}#{feature}.elasticsearch.password\" " +
                              "specified, please only use one of those.")
    end

  end end end
