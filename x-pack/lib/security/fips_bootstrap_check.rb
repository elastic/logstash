# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/environment"

module LogStash
  module Security
    module FipsBootstrapCheck
      extend self
      include LogStash::Util::Loggable

      def check(settings)
        return unless settings.get("xpack.security.fips_mode.enabled")

        required_providers = settings.get("xpack.security.fips_mode.required_providers")
        return if required_providers.empty?

        failures = missing_required_providers(required_providers)
        return if failures.empty?

        raise LogStash::BootstrapCheckError,
          "Logstash is not configured with the required FIPS security providers: #{failures.join('; ')}"
      end

      private

      def missing_required_providers(required_providers)
        observed_providers = ::Java::java.security.Security.getProviders
        required_providers.filter_map do |provider_requirement|
          provider_name, version_pattern = provider_requirement.split(":", 2)
          provider = observed_providers.find { |candidate| candidate.name == provider_name }

          if provider.nil?
            "missing provider #{provider_name.inspect}"
          elsif version_pattern && !version_matches?(provider, version_pattern)
            "provider #{provider_name.inspect} version #{provider.getVersionStr.inspect} does not match #{version_pattern.inspect}"
          end
        end
      end

      def version_matches?(provider, version_pattern)
        version_regex = Regexp.new("\\A#{Regexp.escape(version_pattern).gsub("\\*", ".*")}\\z")
        provider.getVersionStr.match?(version_regex)
      end

    end
  end
end
