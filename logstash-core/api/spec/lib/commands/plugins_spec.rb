# encoding: utf-8
require_relative "../../spec_helper"
require "app/pipeline/stats_command"

describe LogStash::Api::PipelineStatsCommand do

  let(:service) { double("snapshot-service") }

  subject { described_class.new(service) }

  let(:stats) do
    { "events_startup" => 10, "events_in" => 100, "events_filtered" => 200 }
  end

  before(:each) do
    allow(service).to receive(:get).with(:pipeline_stats).and_return(stats)
  end

  context "#schema" do
    let(:report) { subject.run }

    it "return events information" do
      expect(report).to include("events" => { "startup" => 10, "in" => 100, "filtered" => 200 })
    end

  end
end
