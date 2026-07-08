# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "logstash/runner"

describe "Phase 3 remaining FIPS fixes" do
  let(:mock_bcfips) { double("BCFIPSProvider", getName: "BCFIPS") }
  let(:mock_sun)    { double("SunProvider",    getName: "SUN") }

  def with_fips(&block)
    allow(java.security.Security).to receive(:getProvider).with("BCFIPS").and_return(mock_bcfips)
    allow(java.security.Security).to receive(:getProviders).and_return([mock_bcfips, mock_sun])
    block.call
  end

  def without_fips(&block)
    allow(java.security.Security).to receive(:getProvider).with("BCFIPS").and_return(nil)
    allow(java.security.Security).to receive(:getProviders).and_return([mock_sun])
    block.call
  end

  describe "logstash-codec-avro BCFKS keystore validator" do
    before { require "logstash/codecs/avro" }

    it "includes bcfks in ssl_keystore_type validator" do
      config = LogStash::Codecs::Avro.get_config
      expect(config["ssl_keystore_type"][:validate]).to include("bcfks")
    end

    it "includes bcfks in ssl_truststore_type validator" do
      config = LogStash::Codecs::Avro.get_config
      expect(config["ssl_truststore_type"][:validate]).to include("bcfks")
    end

    it "still includes jks in ssl_keystore_type validator" do
      config = LogStash::Codecs::Avro.get_config
      expect(config["ssl_keystore_type"][:validate]).to include("jks")
    end

    it "still includes pkcs12 in ssl_truststore_type validator" do
      config = LogStash::Codecs::Avro.get_config
      expect(config["ssl_truststore_type"][:validate]).to include("pkcs12")
    end
  end

  describe "logstash-filter-elastic_integration FIPS keystore guard" do
    before do
      require "logstash/filters/elastic_integration"
    rescue LoadError => e
      skip("elastic_integration filter not loadable in this environment: #{e.message}")
    end

    it "includes bcfks in ssl_keystore_type validator" do
      config = LogStash::Filters::ElasticIntegration.get_config
      expect(config["ssl_keystore_type"][:validate]).to include("bcfks")
    end

    it "includes bcfks in ssl_truststore_type validator" do
      config = LogStash::Filters::ElasticIntegration.get_config
      expect(config["ssl_truststore_type"][:validate]).to include("bcfks")
    end

    context "in FIPS mode with ssl_keystore_path" do
      it "raises ConfigurationError via validate_ssl_settings!" do
        with_fips do
          ks = Tempfile.new(["ks", ".bcfks"])
          plugin = LogStash::Filters::ElasticIntegration.new(
            "ssl_enabled" => true,
            "ssl_keystore_path" => ks.path,
            "ssl_keystore_password" => "changeit"
          )
          allow(plugin).to receive(:ensure_readable_and_non_writable!)
          expect { plugin.send(:validate_ssl_settings!) }.to raise_error(
            LogStash::ConfigurationError, /ssl_keystore_path.*not supported in FIPS/
          )
        ensure
          ks.close! rescue nil
        end
      end
    end

    context "in FIPS mode with ssl_truststore_path" do
      it "raises ConfigurationError via validate_ssl_settings!" do
        with_fips do
          ts = Tempfile.new(["ts", ".bcfks"])
          plugin = LogStash::Filters::ElasticIntegration.new(
            "ssl_enabled" => true,
            "ssl_truststore_path" => ts.path,
            "ssl_truststore_password" => "changeit"
          )
          allow(plugin).to receive(:ensure_readable_and_non_writable!)
          expect { plugin.send(:validate_ssl_settings!) }.to raise_error(
            LogStash::ConfigurationError, /ssl_truststore_path.*not supported in FIPS/
          )
        ensure
          ts.close! rescue nil
        end
      end
    end

    context "in non-FIPS mode with ssl_keystore_path" do
      it "does not raise a FIPS-specific error" do
        without_fips do
          ks = Tempfile.new(["ks", ".p12"])
          plugin = LogStash::Filters::ElasticIntegration.new(
            "ssl_enabled" => true,
            "ssl_keystore_path" => ks.path,
            "ssl_keystore_password" => "changeit"
          )
          allow(plugin).to receive(:ensure_readable_and_non_writable!)
          begin
            plugin.send(:validate_ssl_settings!)
          rescue LogStash::ConfigurationError => e
            expect(e.message).not_to match(/not supported in FIPS/)
          end
        ensure
          ks.close! rescue nil
        end
      end
    end
  end
end
