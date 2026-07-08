# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "logstash/runner"

describe "Phase 2 FIPS validator changes" do
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

  describe "logstash-filter-fingerprint FIPS algorithm guard" do
    before do
      require "logstash/filters/fingerprint"
    end

    it "raises ConfigurationError for MD5 in FIPS mode" do
      with_fips do
        plugin = LogStash::Filters::Fingerprint.new("method" => "MD5", "source" => ["message"])
        expect { plugin.register }.to raise_error(LogStash::ConfigurationError, /MD5.*not permitted in FIPS/)
      end
    end

    it "raises ConfigurationError for SHA1 in FIPS mode" do
      with_fips do
        plugin = LogStash::Filters::Fingerprint.new("method" => "SHA1", "source" => ["message"])
        expect { plugin.register }.to raise_error(LogStash::ConfigurationError, /SHA1.*not permitted in FIPS/)
      end
    end

    it "allows SHA256 in FIPS mode" do
      with_fips do
        plugin = LogStash::Filters::Fingerprint.new("method" => "SHA256", "source" => ["message"])
        expect { plugin.register }.not_to raise_error
      end
    end

    it "allows MD5 outside FIPS mode" do
      without_fips do
        plugin = LogStash::Filters::Fingerprint.new("method" => "MD5", "source" => ["message"])
        expect { plugin.register }.not_to raise_error
      end
    end
  end

  describe "logstash-filter-anonymize FIPS algorithm guard" do
    before do
      require "logstash/filters/anonymize"
    end

    it "raises ConfigurationError for MD5 in FIPS mode" do
      with_fips do
        plugin = LogStash::Filters::Anonymize.new("algorithm" => "MD5", "key" => "secret", "fields" => ["message"])
        expect { plugin.register }.to raise_error(LogStash::ConfigurationError, /MD5.*not permitted in FIPS/)
      end
    end

    it "raises ConfigurationError for SHA1 in FIPS mode" do
      with_fips do
        plugin = LogStash::Filters::Anonymize.new("algorithm" => "SHA1", "key" => "secret", "fields" => ["message"])
        expect { plugin.register }.to raise_error(LogStash::ConfigurationError, /SHA1.*not permitted in FIPS/)
      end
    end

    it "allows SHA256 in FIPS mode" do
      with_fips do
        plugin = LogStash::Filters::Anonymize.new("algorithm" => "SHA256", "key" => "secret", "fields" => ["message"])
        expect { plugin.register }.not_to raise_error
      end
    end

    it "allows MD5 outside FIPS mode" do
      without_fips do
        plugin = LogStash::Filters::Anonymize.new("algorithm" => "MD5", "key" => "secret", "fields" => ["message"])
        expect { plugin.register }.not_to raise_error
      end
    end
  end

  describe "ssl_keystore_type validators" do
    let(:ls_root) { File.expand_path("../../..", __dir__) }

    it "logstash-mixin-http_client accepts bcfks" do
      require "logstash/plugin_mixins/http_client"
      http_client_file = $LOAD_PATH.map { |p| File.join(p, "logstash/plugin_mixins/http_client.rb") }.find { |f| File.exist?(f) }
      content = File.read(http_client_file)
      expect(content).to include("bcfks")
    end

    it "logstash-output-elasticsearch api_configs accepts bcfks" do
      api_configs_file = Dir.glob(File.join(ls_root, "vendor/bundle/jruby/3.4.0/gems/logstash-output-elasticsearch-*/lib/logstash/plugin_mixins/elasticsearch/api_configs.rb")).first
      content = File.read(api_configs_file)
      expect(content).to include("bcfks")
    end

    it "logstash-input-elasticsearch accepts bcfks" do
      file = Dir.glob(File.join(ls_root, "vendor/bundle/jruby/3.4.0/gems/logstash-input-elasticsearch-*/lib/logstash/inputs/elasticsearch.rb")).first
      content = File.read(file)
      expect(content).to include("bcfks")
    end

    it "logstash-filter-elasticsearch accepts bcfks" do
      file = Dir.glob(File.join(ls_root, "vendor/bundle/jruby/3.4.0/gems/logstash-filter-elasticsearch-*/lib/logstash/filters/elasticsearch.rb")).first
      content = File.read(file)
      expect(content).to include("bcfks")
    end

    it "logstash-input-http accepts bcfks" do
      file = Dir.glob(File.join(ls_root, "vendor/bundle/jruby/3.4.0/gems/logstash-input-http-*/lib/logstash/inputs/http.rb")).first
      content = File.read(file)
      expect(content).to include("bcfks")
    end

    it "logstash-integration-kafka avro_schema_registry accepts BCFKS" do
      file = Dir.glob(File.join(ls_root, "vendor/bundle/jruby/3.4.0/gems/logstash-integration-kafka-*/lib/logstash/plugin_mixins/kafka/avro_schema_registry.rb")).first
      content = File.read(file)
      expect(content).to include("BCFKS")
    end
  end
end
