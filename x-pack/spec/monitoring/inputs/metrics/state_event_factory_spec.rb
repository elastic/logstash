# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/agent"
require "logstash/runner"
require "spec_helper"
require "monitoring/inputs/metrics/state_event_factory"
require 'json'

describe LogStash::Inputs::Metrics::StateEventFactory do
  let(:schemas_path) { File.join(File.dirname(__FILE__), "..", "..", "..", "..", "spec", "monitoring", "schemas") }

  let(:config) {
    config_part = org.logstash.common.SourceWithMetadata.new("local", "...", 0, 0, "input { dummyblockinginput { } } output { null { } }")
    Java::OrgLogstashConfigIr::PipelineConfig.new("DummySource".class, "fake_main".to_sym, [config_part], LogStash::SETTINGS)
  }

  let(:pipeline_settings) { LogStash::Runner::SYSTEM_SETTINGS.clone.merge({
    "pipeline.id" => "main",
    "config.string" => config.config_parts.first.text,
  }) }

  let(:agent) { LogStash::Agent.new(pipeline_settings) }
  let(:metric) { agent.metric }
  let(:collector) { metric.collector }
  let(:agent_task) { start_agent(agent) }

  before :each do
    agent
    agent_task

    wait(60).for { agent.get_pipeline(:main) }.to_not be_nil

    # collector.snapshot_metric is timing dependant and if fired too fast will miss some metrics.
    # after some tests a correct metric_store.size is 72 but when it is incomplete it is lower.
    # I guess this 72 is dependant on the metrics we collect and there is probably a better
    # way to make sure no metrics are missing without forcing a hard sleep but this is what is
    # easily observable, feel free to refactor with a better "timing" test here.
    wait(60).for { collector.snapshot_metric.metric_store.size }.to be >= 72
  end

  after :each do
    agent.shutdown
    agent_task.wait
    LogStash::SETTINGS.set_value("monitoring.enabled", false)
  end

  let(:pipeline) { LogStash::JavaPipeline.new(config) }

  subject(:sut) { described_class.new(pipeline, "funky_cluster_uuid") }

  context "with write direct flag enabled" do
    let(:schema_file) { File.join(schemas_path, "states_document_new_schema.json") }

    it "should create a valid new event shape" do
      LogStash::SETTINGS.set_value("monitoring.enabled", true)

      state_evt = sut.make
      json = JSON.parse(state_evt.to_json)
      expect(json['type']).to eq('logstash_state')
      expect(json['logstash_state']).to be_truthy
      expect(json['logstash_state']['pipeline']).to be_truthy
      expect(JSON::Validator.fully_validate(schema_file, state_evt.to_json)).to be_empty
    end
  end

  context "with write direct flag disabled" do
    let(:schema_file) { File.join(schemas_path, "states_document_schema.json") }

    it "should create a valid old event shape" do
      LogStash::SETTINGS.set_value("monitoring.enabled", false)

      state_evt = sut.make
      expect(JSON::Validator.fully_validate(schema_file, state_evt.to_json)).to be_empty
    end
  end
end
