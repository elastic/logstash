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

        failures = []
        failures.concat(check_provider_ordering)
        failures.concat(check_secure_random_provider)
        failures.concat(check_fips_ready)
        failures.concat(check_jruby_openssl_not_registered)

        required_providers = settings.get("xpack.security.fips_mode.required_providers")
        failures.concat(missing_required_providers(required_providers)) unless required_providers.empty?

        return if failures.empty?

        raise LogStash::BootstrapCheckError,
          "Logstash is not configured in a FIPS-compliant manner:\n  - #{failures.join("\n  - ")}"
      end

      private

      def check_provider_ordering
        first_provider = ::Java::java.security.Security.getProviders.first
        return [] if first_provider&.name == "BCFIPS"
        ["BCFIPS must be the first Java security provider (observed: #{first_provider&.name.inspect})"]
      end

      def check_secure_random_provider
        observed = ::Java::java.security.SecureRandom.new.getProvider.getName
        return [] if observed == "BCFIPS"
        ["Java SecureRandom must be provided by BCFIPS (observed: #{observed.inspect})"]
      end

      def check_fips_ready
        return [] if ::Java::org.bouncycastle.crypto.fips.FipsStatus.isReady
        ["BouncyCastle FIPS is not ready"]
      rescue => e
        ["BouncyCastle FIPS classes are not available: #{e.message}"]
      end

      def check_jruby_openssl_not_registered
        failures = []
        if org.jruby.ext.openssl.SecurityHelper.isProviderRegistered
          failures << "The non-FIPS JRuby OpenSSL security provider must not be registered"
        elsif org.jruby.util.SafePropertyAccessor.getBoolean("jruby.openssl.provider.register") != false
          failures << "The non-FIPS JRuby OpenSSL security provider is eligible for registration; set -Djruby.openssl.provider.register=false"
        end
        failures
      rescue => e
        ["Could not verify JRuby OpenSSL provider state: #{e.message}"]
      end

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
