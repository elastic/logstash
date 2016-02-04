# encoding: utf-8
require "logstash/agent"
require "spec_helper"

describe LogStash::Agent do
  let(:logger) { double("logger") }

  before(:each) do
    allow(logger).to receive(:fatal).with(any_args)
    allow(logger).to receive(:debug).with(any_args)
    allow(logger).to receive(:debug?).with(any_args)
  end

  subject { LogStash::Agent.new({ :logger => logger }) }

  context "#node_name" do
    let(:hostname) { "the-logstash" }

    before(:each) do
      allow(Socket).to receive(:gethostname).and_return(hostname)
    end

    it "fallback to hostname when no name is provided" do
      expect(subject.node_name).to be(hostname)
    end

    it "uses the user provided name" do
      expect(LogStash::Agent.new({ :node_name => "a-name" }).node_name).to eq("a-name")
    end
  end

  context "#node_uuid" do
    it "create a unique uuid between agent instances" do
      expect(subject.node_uuid).not_to be(LogStash::Agent.new.node_uuid)
    end
  end

  context "#started_at" do
    it "return the start time when the agent is started" do
      expect(subject.started_at).to be_kind_of(Time)
    end
  end

  context "#uptime" do
    it "return the number of milliseconds since start time" do
      expect(subject.uptime).to be >= 0
    end
  end
end
