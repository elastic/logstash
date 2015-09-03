# encoding: utf-8
require "spec_helper"
require "logstash/config/defaults"

describe LogStash::Config::Defaults do
  it ".cpu_cores should return a positive integer" do
    expect(described_class.cpu_cores.nil?).to be false
    expect(described_class.cpu_cores.zero?).to be false
  end
end
