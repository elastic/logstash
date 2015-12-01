# encoding: utf-8
require "logstash/instrument/probe/os"

describe LogStash::Instrument::Probe::Os do
  it "returns the load average" do
    expect(subject.system_load_average).to be > 0
  end

  it "return the architecture" do
    expect(subject.fs.total_physical_memory_size).to eq("")
  end
end
