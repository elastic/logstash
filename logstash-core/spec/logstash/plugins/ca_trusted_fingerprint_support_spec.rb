require "spec_helper"

require "logstash/plugin"

require 'logstash/inputs/base'
require 'logstash/filters/base'
require 'logstash/codecs/base'
require 'logstash/outputs/base'
java_import "org.logstash.util.CATrustedFingerprintTrustStrategy"

describe LogStash::Plugins::CATrustedFingerprintSupport do
  let(:ca_trusted_fingerprint_support) { described_class }

  [
      LogStash::Inputs::Base,
      LogStash::Filters::Base,
      LogStash::Codecs::Base,
      LogStash::Outputs::Base
  ].each do |base_class|
    context "that inherits from `#{base_class}`" do
      let(:plugin_base_class) { base_class }

      subject(:plugin_class) do
        Class.new(plugin_base_class) do
          config_name 'sample'

          include LogStash::Plugins::CATrustedFingerprintSupport
        end
      end

      it 'defines a `trust_strategy_for_ca_trusted_fingerprint` method' do
        expect(plugin_class.method_defined?(:trust_strategy_for_ca_trusted_fingerprint)).to be true
      end

      let(:options) { Hash.new }
      let(:plugin) { plugin_class.new(options) }

      context '#initialize' do
        shared_examples 'normalizes fingerprints' do
          context '#ca_trusted_fingerprint' do
            it "normalizes to an array of capital hex fingerprints" do
              expect(plugin.ca_trusted_fingerprint).to eq(normalized)
            end
          end
          context '#trust_strategy_for_ca_trusted_fingerprint' do
            it 'builds an appropriate trust strategy' do
              expect(CATrustedFingerprintTrustStrategy).to receive(:new).with(normalized).and_call_original
              expect(plugin.trust_strategy_for_ca_trusted_fingerprint).to be_a_kind_of(org.apache.http.conn.ssl.TrustStrategy)
            end
          end
        end

        shared_examples 'rejects bad input in the usual way' do
          let(:logger_stub) { double('Logger').as_null_object }
          before(:each) do
            allow(plugin_class).to receive(:logger).and_return(logger_stub)
          end
          it 'logs helpfully and raises an exception' do
            expect {plugin}.to raise_exception(LogStash::ConfigurationError)
            expect(logger_stub).to have_received(:error).with(a_string_including "Expected a hex-encoded SHA-256 fingerprint")
          end
        end

        context 'without a `ca_trusted_fingerprint`' do
          context '#ca_trusted_fingerprint' do
            it 'returns nil' do
              expect(plugin.ca_trusted_fingerprint).to be_nil
            end
          end
          context '#trust_strategy_for_ca_trusted_fingerprint' do
            it 'returns nil' do
              expect(plugin.trust_strategy_for_ca_trusted_fingerprint).to be_nil
            end
          end
        end

        context 'with a single `ca_trusted_fingerprint`' do
          let(:options) { super().merge('ca_trusted_fingerprint' => input) }
          context 'that is valid' do
            let(:input) { "1b:ad:1d:ea:" * 8 }
            include_examples('normalizes fingerprints') do
              let(:normalized) { ['1BAD1DEA' * 8] }
            end
          end
          context 'that is not valid' do
            let(:input) { "NOPE" }
            include_examples('rejects bad input in the usual way')
          end
        end

        context 'with multiple `ca_trusted_fingerprint` values' do
          let(:options) { super().merge('ca_trusted_fingerprint' => input) }
          context 'that are valid' do
            let(:input) { ["1b:ad:1d:ea:" * 8, 'BEefCaB1' * 8] }
            include_examples('normalizes fingerprints') do
              let(:normalized) { ["1BAD1DEA" * 8, "BEEFCAB1" * 8] }
            end
          end
          context 'that is not valid' do
            let(:input) { ["NOPE", "1BAD1DEA" * 8] }

            include_examples('rejects bad input in the usual way')
          end
        end
      end
    end
  end
end
