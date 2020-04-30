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
  end

end
