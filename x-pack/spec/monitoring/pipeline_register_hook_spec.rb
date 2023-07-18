# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require 'monitoring/monitoring'

describe LogStash::MonitoringExtension::PipelineRegisterHook do
  subject(:monitoring_extension) { described_class.new }

  let(:settings) {
                   settings = @sys_settings.clone
                   settings.set_value("xpack.monitoring.enabled", true)
                   settings.set_value("xpack.monitoring.elasticsearch.hosts", "http://localhost:9200")
                   settings.set_value("xpack.monitoring.elasticsearch.username", "elastic")
                   settings.set_value("xpack.monitoring.elasticsearch.password", "changeme")
                   settings
                 }

  before(:all) {
    @extension = LogStash::MonitoringExtension.new
    # used to register monitoring xpack's settings
    @sys_settings = LogStash::Runner::SYSTEM_SETTINGS.clone
    @extension.additionals_settings(@sys_settings)
  }

  context 'validate monitoring settings' do
    it "work without any monitoring settings" do
      settings.set_value("xpack.monitoring.enabled", true)
      expect(subject.generate_pipeline_config(settings)).to be_truthy
    end

    it "monitoring.enabled should conflict with xpack.monitoring.enabled" do
      settings.set_value("xpack.monitoring.enabled", true)
      settings.set_value("monitoring.enabled", true)

      expect {
        subject.generate_pipeline_config(settings)
      }.to raise_error(ArgumentError)
    end

    it "monitoring.* should conflict with any xpack.monitoring.*" do
      settings.set_value("xpack.monitoring.collection.interval", "10s")
      settings.set_value("monitoring.enabled", true)

      expect {
        subject.generate_pipeline_config(settings)
      }.to raise_error(ArgumentError)
    end

    context 'ssl certificate verification setting' do
    { 'full' => 'full',
      'certificate' => 'full',
      'none' => 'none',
       nil => 'full', # unset, uses default
    }.each do |setting_value, expected_result|
        context "ssl certificate verification setting with `xpack.monitoring.elasticsearch.ssl.verification_mode` #{setting_value ? "set to `#{setting_value}`" : 'unset'}" do
          let(:settings) {
                           settings = super().merge("xpack.monitoring.elasticsearch.hosts" => "https://localhost:9200")
                           setting_value.nil? ? settings : settings.merge("xpack.monitoring.elasticsearch.ssl.verification_mode" => setting_value)
                         }

          it "the generated pipeline includes `ssl_verification_mode => #{expected_result}`" do
            generated_pipeline_config = subject.generate_pipeline_config(settings)
            expect(generated_pipeline_config).to include("ssl_verification_mode => #{expected_result}")
          end
        end
      end
    end

    context 'ssl ca_trusted_fingerprint setting' do
      let(:ca_trusted_fingerprint) { SecureRandom.hex(32) }
      let(:settings) { super().merge("xpack.monitoring.elasticsearch.ssl.ca_trusted_fingerprint" => ca_trusted_fingerprint) }

      context 'the generated pipeline' do
        subject(:generated_pipeline_config) { monitoring_extension.generate_pipeline_config(settings) }

        it %Q(includes `ca_trusted_fingerprint` with the value of the provided `ssl.ca_trusted_fingerprint`) do
          expect(generated_pipeline_config).to include(%Q(ca_trusted_fingerprint => "#{ca_trusted_fingerprint}"))
        end
      end
    end

    context 'ssl cipher suites setting' do
      let(:settings) { super().merge("xpack.monitoring.elasticsearch.ssl.cipher_suites" => ["FOO", "BAR"]) }

      context 'the generated pipeline' do
        subject(:generated_pipeline_config) { monitoring_extension.generate_pipeline_config(settings) }

        it 'The generated pipeline includes `ssl_cipher_suites`' do
          expect(generated_pipeline_config).to include('ssl_cipher_suites => ["FOO", "BAR"]')
        end
      end
    end

    context 'ssl keystore setting' do
      let(:ssl_keystore_path) { Tempfile.new('ssl_keystore_file') }
      let(:settings) { super().merge(
        "xpack.monitoring.elasticsearch.ssl.keystore.path" => ssl_keystore_path.path,
        "xpack.monitoring.elasticsearch.ssl.keystore.password" => "foo"
      ) }

      context 'the generated pipeline' do
        subject(:generated_pipeline_config) { monitoring_extension.generate_pipeline_config(settings) }

        it 'The generated pipeline includes `ssl_keystore_path` and `ssl_keystore_password`' do
          expect(generated_pipeline_config).to include("ssl_keystore_path => \"#{ssl_keystore_path.path}\"")
          expect(generated_pipeline_config).to include('ssl_keystore_password => "foo"')
        end
      end
    end

    context 'ssl truststore setting' do
      let(:ssl_truststore_path) { Tempfile.new('ssl_truststore_file') }
      let(:settings) do
        super().merge(
          "xpack.monitoring.elasticsearch.ssl.truststore.path" => ssl_truststore_path.path,
          "xpack.monitoring.elasticsearch.ssl.truststore.password" => "foo"
        )
      end

      context 'the generated pipeline' do
        subject(:generated_pipeline_config) { monitoring_extension.generate_pipeline_config(settings) }

        it 'The generated pipeline includes `ssl_truststore_path` and `ssl_truststore_password`' do
          expect(generated_pipeline_config).to include("ssl_truststore_path => \"#{ssl_truststore_path.path}\"")
          expect(generated_pipeline_config).to include('ssl_truststore_password => "foo"')
        end
      end
    end

    context 'ssl certificate setting' do
      let(:ssl_certificate_path) { Tempfile.new('ssl_certificate_file') }
      let(:ssl_key_path) { Tempfile.new('ssl_key_file') }
      let(:settings) do
        super().merge(
          "xpack.monitoring.elasticsearch.ssl.certificate" => ssl_certificate_path.path,
          "xpack.monitoring.elasticsearch.ssl.key" => ssl_key_path.path
        )
      end

      context 'the generated pipeline' do
        subject(:generated_pipeline_config) { monitoring_extension.generate_pipeline_config(settings) }

        it 'The generated pipeline includes `ssl_truststore_path` and `ssl_truststore_password`' do
          expect(generated_pipeline_config).to include("ssl_certificate => \"#{ssl_certificate_path.path}\"")
          expect(generated_pipeline_config).to include("ssl_key => \"#{ssl_key_path.path}\"")
        end
      end
    end
  end
end
