# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require 'monitoring/monitoring'

describe LogStash::MonitoringExtension::PipelineRegisterHook do

  subject { described_class.new }

  before(:all) {
    @extension = LogStash::MonitoringExtension.new
    # used to register monitoring xpack's settings
    @sys_settings = LogStash::Runner::SYSTEM_SETTINGS.clone
    @extension.additionals_settings(@sys_settings)
  }

  context 'validate monitoring settings' do
    it "work without any monitoring settings" do
      settings = @sys_settings.clone
      settings.set_value("xpack.monitoring.enabled", true)
      settings.set_value("xpack.monitoring.elasticsearch.hosts", "http://localhost:9200")
      settings.set_value("xpack.monitoring.elasticsearch.username", "elastic")
      settings.set_value("xpack.monitoring.elasticsearch.password", "changeme")
      expect(subject.generate_pipeline_config(settings)).to be_truthy
    end

    it "monitoring.enabled should conflict with xpack.monitoring.enabled" do
      settings = @sys_settings.clone
      settings.set_value("xpack.monitoring.enabled", true)
      settings.set_value("monitoring.enabled", true)

      expect {
        subject.generate_pipeline_config(settings)
      }.to raise_error(ArgumentError)
    end

    it "monitoring.* should conflict with any xpack.monitoring.*" do
      settings = @sys_settings.clone
      settings.set_value("xpack.monitoring.collection.interval", "10s")
      settings.set_value("monitoring.enabled", true)

      expect {
        subject.generate_pipeline_config(settings)
      }.to raise_error(ArgumentError)
    end

    context 'ssl certificate verification setting' do
      {
        'certificate' => 'true',
        'none'        => 'false',
        nil           => 'true', # unset, uses default
      }.each do |setting_value, expected_result|
        context "with `xpack.monitoring.elasticsearch.ssl.verification_mode` #{setting_value ? "set to `#{setting_value}`" : 'unset'}" do
          it "the generated pipeline includes `ssl_certificate_verification => #{expected_result}`" do
            settings = @sys_settings.clone.tap(&:reset)
            settings.set_value("xpack.monitoring.enabled", true)
            settings.set_value("xpack.monitoring.elasticsearch.hosts", "https://localhost:9200")
            settings.set_value("xpack.monitoring.elasticsearch.username", "elastic")
            settings.set_value("xpack.monitoring.elasticsearch.password", "changeme")

            settings.set_value("xpack.monitoring.elasticsearch.ssl.verification_mode", setting_value) unless setting_value.nil?

            generated_pipeline_config = subject.generate_pipeline_config(settings)

            expect(generated_pipeline_config).to include("ssl_certificate_verification => #{expected_result}")
          end
        end
      end
    end
  end

end
