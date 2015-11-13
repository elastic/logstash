# encoding: utf-8
require "logstash/agent"
require "spec_helper"

describe LogStash::Agent do
  def make_agent(options={})
    LogStash::Agent.new(Cabin::Channel.get(), options)
  end

  context "#node_name" do
    let(:hostname) { "the-logstash" }

    before do
      allow(Socket).to receive(:gethostname).and_return(hostname)
    end

    it "fallback to hostname when no name is provided" do
      expect(make_agent.node_name).to be(hostname)
    end

    it "uses the user provided name" do
      expect(make_agent({ :node_name => "a-name" }).node_name).to eq("a-name")
    end
  end

  context "#node_uuid" do
    it "create a unique uuid between agent instances" do
      expect(make_agent.node_uuid).not_to be(make_agent.node_uuid)
    end
  end
end
