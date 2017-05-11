# encoding: utf-8
require "spec_helper"
require "logstash/pipeline"
require "logstash/config/source/local"
require "logstash/pipeline_reporter"
require_relative "../support/mocks_classes"

#TODO: Figure out how to add more tests that actually cover inflight events
#This will require some janky multithreading stuff
describe LogStash::PipelineReporter do
  let(:generator_count) { 5 }
  let(:config) do
    "input { generator { count => #{generator_count} } } output { dummyoutput {} } "
  end
  let(:metric) { nil }
  let(:pipeline_id) { :main }
  let(:settings) { LogStash::SETTINGS }
  let(:config_parts) { ::LogStash::Config::Source::Local::ConfigStringLoader.read(config) }
  let(:pipeline_config) { ::LogStash::Config::PipelineConfig.new(nil, pipeline_id, config_parts, settings) }
  let(:pipeline) { LogStash::Pipeline.new(pipeline_config, metric) }
  let(:reporter) { pipeline.reporter }

  before do
    allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)
    allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_call_original
    allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_call_original

    @pre_snapshot = reporter.snapshot
    
    pipeline.run
    @post_snapshot = reporter.snapshot
  end

  after do
    pipeline.shutdown
  end

  describe "events filtered" do
    it "should start at zero" do
      expect(@pre_snapshot.events_filtered).to eql(0)
    end

    it "should end at the number of generated events" do
      expect(@post_snapshot.events_filtered).to eql(generator_count)
    end
  end

  describe "events consumed" do
    it "should start at zero" do
      expect(@pre_snapshot.events_consumed).to eql(0)
    end

    it "should end at the number of generated events" do
      expect(@post_snapshot.events_consumed).to eql(generator_count)
    end
  end

  describe "inflight count" do
    it "should be zero before running" do
      expect(@pre_snapshot.inflight_count).to eql(0)
    end

    it "should be zero after running" do
      expect(@post_snapshot.inflight_count).to eql(0)
    end
  end
end
