# encoding: utf-8
require_relative "../../spec_helper"
require "app/commands/stats/events_command"
require 'ostruct'

describe LogStash::Api::StatsEventsCommand do

  let(:service) { double("snapshot-service") }

  subject { described_class.new(service) }

  let(:stats) do
    { "stats" => { "events" => { "in" => 100,
                                 "out" => 0,
                                 "filtered" => 200 }}}
  end

  before(:each) do
    allow(service).to receive(:get).with(:events_stats).and_return(LogStash::Json.dump(stats))
  end

  context "#schema" do
    let(:report) { subject.run }

    it "return events information" do
      expect(report).to include({"in" => 100, "filtered" => 200 })
    end

  end
end
