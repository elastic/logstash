
require "logstash/environment"

require "logstash/plugins/registry"

module LogStash
  class FipsValidation < LogStash::UniversalPlugin

    include LogStash::Util::Loggable

    require 'java'
    java_import org.jruby.util.SafePropertyAccessor

    def register_hooks(hooks)
      logger.debug("registering hooks")
      require 'logstash/runner'
      hooks.register_hooks(LogStash::Runner, self)
    end

    def before_bootstrap_checks(runner)
      logger.debug("running before_bootstrap_checks")
      accumulator = Accumulator.new(self)

      # naive security provider check: specific three in specific order before any others
      observed_security_providers = ::Java::java.security.Security.getProviders.map(&:name)
      expected_security_providers = %w(BCFIPS BCJSSE SUN)
      if observed_security_providers.first(3) == expected_security_providers
        accumulator.success "Java security providers are properly configured (observed `#{observed_security_providers}`)"
      else
        accumulator.failure "Java security providers are misconfigured (expected `#{expected_security_providers}` to be first 3, observed `#{observed_security_providers}`)"
      end

      # naive secure-random provider check:
      observed_random_provider = ::Java::java.security.SecureRandom.new.getProvider.getName
      expected_random_provider = "BCFIPS"
      if observed_random_provider != expected_random_provider
        accumulator.failure "Java SecureRandom provider is misconfigured (expected `#{expected_random_provider}`; observed `#{observed_random_provider}`)"
      else
        accumulator.success "Java SecureRandom provider is properly configured (observed `#{observed_random_provider}`)"
      end

      # ensure Bouncycastle is configured and ready
      begin
        if Java::org.bouncycastle.crypto.CryptoServicesRegistrar.isInApprovedOnlyMode
          accumulator.success "Bouncycastle Crypto is in `approved-only` mode"
        else
          accumulator.failure "Bouncycastle Crypto is not in 'approved-only' mode"
        end

        if ::Java::org.bouncycastle.crypto.fips.FipsStatus.isReady
          accumulator.success "Bouncycastle Crypto is fips-ready"
        else
          accumulator.failure "Bouncycastle Crypto is not fips-ready"
        end
      rescue => ex
        accumulator.failure "Bouncycastle Crypto unavailable: (#{ex.class}) #{ex.message}"
      end

      # ensure non-compliant jruby openssl provider isn't registered or eligible for later registration
      if org.jruby.ext.openssl.SecurityHelper.isProviderRegistered
        accumulator.failure "non-compliant Jruby OpenSSL security helper is registered"
      elsif org.jruby.util.SafePropertyAccessor.getBoolean("jruby.openssl.provider.register") != false
        accumulator.failure "non-compliant Jruby OpenSSL security helper is eligible to be registered"
      else
        accumulator.success "non-compliant Jruby OpenSSL security helper is correctly not registered"
      end

      # hard-exit if there were _any_ failures
      if accumulator.failure?
        logger.fatal "Logstash is not configured in a FIPS-compliant manner"
        exit 1
      end

      logger.info("FIPS OK")
    end

    class Accumulator
      def initialize(logger_context)
        @logger = logger_context.logger
        @success = []
        @failure = []
      end

      def success(message)
        @success << message
        @logger.info(message)
      end

      def failure(message)
        @failure << message
        @logger.error(message)
      end

      def failure?
        @failure.any?
      end
    end
  end
end
