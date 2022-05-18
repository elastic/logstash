module LogStash
  module Plugins
    module CATrustedFingerprintSupport
      def self.included(base)
        fail(ArgumentError) unless base < LogStash::Plugin

        base.config(:ca_trusted_fingerprint, :validate => :sha_256_hex, :list => true)
      end

      extend LogStash::Util::ThreadSafeAttributes

      lazy_init_attr(:trust_strategy_for_ca_trusted_fingerprint,
                     variable: :@_trust_strategy_for_ca_trusted_fingerprint) do
        require 'logstash/patches/manticore/trust_strategies'
        @ca_trusted_fingerprint && org.logstash.util.CATrustedFingerprintTrustStrategy.new(@ca_trusted_fingerprint)
      end
    end
  end
end
