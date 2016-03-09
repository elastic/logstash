# encoding: utf-8
require_relative "../../spec_helper"
require "app/commands/stats/events_command"

describe LogStash::Api::StatsEventsCommand do

  context "#schema" do
    let(:report) { subject.run }

    it "return events information" do
      expect(report).to include("in", "filtered", "out")
    end

  end
end
