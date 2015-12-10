# encoding: utf-8
require "logstash/instrument/probe/os"

describe LogStash::Instrument::Probe::Os do
  it "returns the load average" do
    expect(subject.system_load_average).to be > 0
  end
end
