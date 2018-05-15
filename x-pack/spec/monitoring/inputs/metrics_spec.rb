# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash-core"
require "logstash/agent"
require "monitoring/inputs/metrics"
require "rspec/wait"
require 'spec_helper'
require "json"
require "json-schema"
require 'license_checker/x_pack_info'
require 'monitoring/monitoring'

describe LogStash::Inputs::Metrics do
  let(:xpack_monitoring_interval) { 1 }
  let(:options) { { "collection_interval" => xpack_monitoring_interval,
                      "collection_timeout_interval" => 600 } }
  let(:elasticsearch_url) { nil }
  let(:elasticsearch_username) { nil }
  let(:elasticsearch_password) { nil }


  subject { described_class.new(options) }
  let(:settings) do
    {
        "xpack.monitoring.enabled" => true,
        "xpack.monitoring.elasticsearch.url" => elasticsearch_url,
        "xpack.monitoring.elasticsearch.username" => elasticsearch_username,
        "xpack.monitoring.elasticsearch.password" => elasticsearch_password,
    }
  end

  let(:es_options) do
    {
        'url' => elasticsearch_url,
        'user' => elasticsearch_username,
        'password' => elasticsearch_password
    }
  end


  context "integration" do

    shared_examples_for 'events are added to the queue' do
      it 'should add a stats events to the queue' do
        expect(stats_events.size).to eq(1)
      end

      it 'should add two state events to the queue' do
        # Triggered event plus the one from `update`
        expect(state_events.size).to eq(2)
      end
    end

    shared_examples_for 'events are not added to the queue' do
      it 'should not add a stats events to the queue' do
        expect(stats_events.size).to eq(0)
      end

      it 'should not add a state events to the queue' do
        # Triggered event plus the one from `update`
        expect(state_events.size).to eq(0)
      end
    end

    let(:schemas_path) { File.join("spec", "monitoring", "schemas") }
    let(:queue) { [] }

    let(:number_of_events) { 20 }
    let(:config) { "input { generator { count => #{number_of_events} } } output { null { } }" }

    let(:pipeline_settings) { LogStash::Runner::SYSTEM_SETTINGS.clone.merge({
      "pipeline.id" => "main",
      "config.string" => config,
    }) }

    let(:agent) { LogStash::Agent.new(pipeline_settings) }
    let(:metric) { agent.metric }
    let(:collector) { metric.collector }

    # Can't use let because this value can change over time
    def stats_events
      queue.select do |e|
        e.get("[@metadata][document_type]") == "logstash_stats"
      end
    end

    # Can't use let because this value can change over time
    def state_events
      queue.select do |e|
        e.get("[@metadata][document_type]") == "logstash_state"
      end
    end

    before :each do
      allow(subject).to receive(:fetch_global_stats).and_return({"uuid" => "00001" })
    end

    def setup_pipeline
      agent.execute

      100.times do
        sleep 0.1
        break if main_pipeline
      end
      raise "No main pipeline registered!" unless main_pipeline

      subject.metric = metric

      subject.register
      subject.run(queue)
      subject.pipeline_started(agent, main_pipeline)
    end

    def main_pipeline
      agent.get_pipeline(:main)
    end

    after :each do
      agent.shutdown
    end

    let(:license_state_ok) do
      {:state => :ok, :log_level => :info, :log_message => 'Monitoring License OK'}
    end

    context 'after the pipeline is setup' do
      before do
        allow(subject).to receive(:setup_license_checker)
        allow(subject).to receive(:es_options_from_settings_or_modules).and_return(es_options)
        allow(subject).to receive(:get_current_license_state).and_return(license_state_ok)
        allow(subject).to receive(:exec_timer_task)
        allow(subject).to receive(:sleep_till_stop)
        setup_pipeline
      end
      it "should store the agent" do
        expect(subject.agent).to eq(agent)
      end
    end

    describe "#update" do
      before :each do
        allow(subject).to receive(:fetch_global_stats).and_return({"uuid" => "00001" })
        allow(subject).to receive(:setup_license_checker)
        allow(subject).to receive(:es_options_from_settings_or_modules).and_return(es_options)
        allow(subject).to receive(:get_current_license_state).and_return(license_state_ok)
        allow(subject).to receive(:exec_timer_task)
        allow(subject).to receive(:sleep_till_stop)
        setup_pipeline
        subject.update(collector.snapshot_metric)
      end

      it_behaves_like 'events are added to the queue'

      describe "state event" do
        let(:schema_file) { File.join(schemas_path, "states_document_schema.json") }
        let(:event) { state_events.first }

        it "should validate against the schema" do
          expect(event).to be_a(LogStash::Event)
          expect(JSON::Validator.fully_validate(schema_file, event.to_json)).to be_empty
        end
      end

      describe "#build_event" do
        let(:schema_file) { File.join(schemas_path, "monitoring_document_schema.json") }

        describe "data event" do
          let(:event) { stats_events.first }
          it "has the correct schema" do
            expect(event).to be_a(LogStash::Event) # Check that we actually have an event...
            expect(JSON::Validator.fully_validate(schema_file, event.to_json)).to be_empty
          end
        end
      end
    end

    context 'license testing' do
      let(:elasticsearch_url) { ["https://localhost:9898"] }
      let(:elasticsearch_username) { "elastictest" }
      let(:elasticsearch_password) { "testchangeme" }
      let(:mock_license_client) { double("es_client")}
      let(:license_subject) {   subject { described_class.new(options) }}
      let(:license_reader) { LogStash::LicenseChecker::LicenseReader.new(system_settings, 'monitoring', es_options)}
      let(:extension) {  LogStash::MonitoringExtension.new }
      let(:system_settings) { LogStash::Runner::SYSTEM_SETTINGS.clone }
      let(:license_status) { 'active'}
      let(:license_type) { 'trial' }
      let(:license_expiry_date) { Time.now + (60 * 60 * 24)}
      let(:license_expiry_in_millis) { license_expiry_date.to_i * 1000 }

      let(:xpack_response) {
        LogStash::Json.load("{
          \"license\": {
            \"status\": \"#{license_status}\",
            \"uid\": \"9a48c67c-ce2c-4169-97bf-37d324b8ab80\",
            \"type\": \"#{license_type}\",
            \"expiry_date_in_millis\": #{license_expiry_in_millis}
          }
        }")
      }


      let(:no_xpack_response) {
        LogStash::Json.load("{
          \"error\": {
            \"root_cause\": [
              {
                \"type\": \"index_not_found_exception\",
                \"reason\": \"no such index\",
                \"resource.type\": \"index_or_alias\",
                \"resource.id\": \"_xpack\",
                \"index_uuid\": \"_na_\",
                \"index\": \"_xpack\"
              }],
            \"type\": \"index_not_found_exception\",
            \"reason\": \"no such index\",
            \"resource.type\": \"index_or_alias\",
            \"resource.id\": \"_xpack\",
            \"index_uuid\": \"_na_\",
            \"index\": \"_xpack\"
          },
          \"status\": 404
        }")
      }

      let(:no_xpack_response_5_6) {
        LogStash::Json.load("{
         \"error\": {
            \"root_cause\":
              [{
                \"type\":\"illegal_argument_exception\",
                \"reason\": \"No endpoint or operation is available at [_xpack]\"
              }],
                \"type\":\"illegal_argument_exception\",
                \"reason\": \"No endpoint or operation is available at [_xpack]\"
              },
              \"status\": 400
          }")
        }


      let(:settings) do
        {
            "xpack.monitoring.enabled" => true,
            "xpack.monitoring.elasticsearch.url" => elasticsearch_url,
            "xpack.monitoring.elasticsearch.username" => elasticsearch_username,
            "xpack.monitoring.elasticsearch.password" => elasticsearch_password,
        }
      end

      before :each do
        extension.additionals_settings(system_settings)
        apply_settings(settings, system_settings)
        allow(subject).to receive(:fetch_global_stats).and_return({"uuid" => "00001" })
        allow(subject).to receive(:es_options_from_settings_or_modules).and_return(es_options)
        allow(subject).to receive(:exec_timer_task)
        allow(subject).to receive(:sleep_till_stop)

        allow(subject).to receive(:license_reader).and_return(license_reader)
        allow(license_reader).to receive(:build_client).and_return(mock_license_client)
      end

      describe 'with licensing' do
        context 'when xpack has not been installed on es 6' do
          before :each do
            expect(mock_license_client).to receive(:get).with('_xpack').and_return(no_xpack_response)
            setup_pipeline
            subject.update(collector.snapshot_metric)
          end

          it_behaves_like 'events are not added to the queue'
        end

        context 'when xpack has not been installed on 5.6' do
          before :each do
            expect(mock_license_client).to receive(:get).with('_xpack').and_return(no_xpack_response_5_6)
            setup_pipeline
            subject.update(collector.snapshot_metric)
          end

          it_behaves_like 'events are not added to the queue'
        end

        context 'when the license has expired' do
          let(:license_status) { 'expired'}
          let(:license_expiry_date) { Time.now - (60 * 60 * 24)}

          before :each do
            expect(mock_license_client).to receive(:get).with('_xpack').and_return(xpack_response)
            setup_pipeline
            subject.update(collector.snapshot_metric)
          end

          it_behaves_like 'events are added to the queue'
        end

        context 'when the license server is not available' do
          let(:mock_license_client) { double('license_client')}
          before :each do
            expect(mock_license_client).to receive(:get).and_raise("An error is here")
            setup_pipeline
            subject.update(collector.snapshot_metric)
          end

          it_behaves_like 'events are not added to the queue'
        end

        %w(basic standard trial standard gold platinum).sample(1).each  do |license_type|
          context "With a valid #{license_type} license" do
            let(:license_type) { license_type }
            before :each do
              expect(mock_license_client).to receive(:get).with('_xpack').and_return(xpack_response)
              setup_pipeline
              subject.update(collector.snapshot_metric)
            end
            it_behaves_like 'events are added to the queue'
          end
        end
      end
    end
  end

  context "unit tests" do
    let(:queue) { double("queue").as_null_object }

    before do
      allow(subject).to receive(:queue).and_return(queue)
    end

    describe "#update_pipeline_state" do
      let(:pipeline) { double("pipeline") }
      let(:state_event) { double("state event") }

      describe "system pipelines" do
        before(:each) do
          allow(subject).to receive(:valid_license?).and_return(true)
          allow(pipeline).to receive(:system?).and_return(true)
          allow(subject).to receive(:emit_event)
          subject.update_pipeline_state(pipeline)
        end

        it "should not emit any events" do
          expect(subject).not_to have_received(:emit_event)
        end
      end

      describe "normal pipelines" do
        before(:each) do
          allow(subject).to receive(:valid_license?).and_return(true)
          allow(pipeline).to receive(:system?).and_return(false)
          allow(subject).to receive(:state_event_for).with(pipeline).and_return(state_event)
          allow(subject).to receive(:emit_event)
          subject.update_pipeline_state(pipeline)
        end

        it "should emit an event" do
          expect(subject).to have_received(:emit_event).with(state_event)
        end
      end
    end
  end
end
