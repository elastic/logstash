# encoding: utf-8

require 'manticore'

unless defined?(::Manticore::Client::TrustStrategies)
  module CATrustedFingerprintSupport
    # @override
    def setup_trust_store(ssl_options, context, trust_strategy)
      if ssl_options.include?(:trust_strategy)
        trust_strategy = TrustStrategies.combine(trust_strategy, ssl_options.fetch(:trust_strategy))
      end

      super(ssl_options, context, trust_strategy)
    end

    module TrustStrategies
      def self.combine(lhs, rhs)
        return rhs if lhs.nil?
        return lhs if rhs.nil?

        Multiple.new([lhs, rhs])
      end

      class Multiple
        include ::Java::OrgApacheHttpConnSSL::TrustStrategy

        def initialize(trust_strategies)
          @trust_strategies = trust_strategies.compact
          super()
        end

        # boolean isTrusted(X509Certificate[] chain, String authType) throws CertificateException;
        def trusted?(x509_certificate_chain, auth_type)
          @trust_strategies.any? do |trust_strategy|
            trust_strategy.trusted?(x509_certificate_chain, auth_type)
          end
        end
      end
    end
  end
  ::Manticore::Client.send(:prepend, CATrustedFingerprintSupport)
end