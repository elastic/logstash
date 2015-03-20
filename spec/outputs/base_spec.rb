# encoding: utf-8
require "spec_helper"

# use a dummy NOOP output to test Outputs::Base
class LogStash::Outputs::NOOP < LogStash::Outputs::Base
  config_name "noop"
  milestone 2

  def register; end

  def receive(event)
    return output?(event)
  end
end

describe "LogStash::Outputs::Base#output?" do
  it "should filter by type" do
    output = LogStash::Outputs::NOOP.new("type" => "noop")
    expect(output.receive(LogStash::Event.new({"type" => "noop"}))).to eq(true)
    expect(output.receive(LogStash::Event.new({"type" => "not_noop"}))).to eq(false)
  end
  
  it "should filter by tags" do
    output = LogStash::Outputs::NOOP.new("tags" => ["value", "value2"])
    expect(output.receive(LogStash::Event.new({"tags" => ["value","value2"]}))).to eq(true)
    expect(output.receive(LogStash::Event.new({"tags" => ["notvalue"]}))).to eq(false)
    expect(output.receive(LogStash::Event.new({"tags" => ["value"]}))).to eq(false)
  end

  it "should exclude by tags" do
    output = LogStash::Outputs::NOOP.new("exclude_tags" => ["value"])
    expect(output.receive(LogStash::Event.new({"tags" => ["value"]}))).to eq(false)
    expect(output.receive(LogStash::Event.new({"tags" => ["notvalue"]}))).to eq(true)
  end

  it "should receive only one time with default 'retries'" do
    output = LogStash::Outputs::NOOP.new()

    output.should_receive(:receive).once

    output.handle(LogStash::Event.new())

  end

  it "should call receive one time plus 'retries'" do
    retries = 3
    output = LogStash::Outputs::NOOP.new("retries" => retries)

    output.stub(:receive) { raise "any unrescued error from the output" }
    output.should_receive(:receive).exactly(1 + retries).times

    expect{ output.handle(LogStash::Event.new()) }.to raise_error
  end

  it "should shutdown when exception is raised and on_error_strategy is default 'shutdown'" do
    output = LogStash::Outputs::NOOP.new()

    output.stub(:receive) { raise "any unrescued error from the output" }

    expect{ output.handle(LogStash::Event.new()) }.to raise_error
  end

  it "should ignore when exception is raised and on_error_strategy is 'ignore'" do
    output = LogStash::Outputs::NOOP.new("on_error_strategy" => "ignore")

    output.stub(:receive) { raise "any unrescued error from the output" }

    expect{ output.handle(LogStash::Event.new()) }.to_not raise_error
  end

end
