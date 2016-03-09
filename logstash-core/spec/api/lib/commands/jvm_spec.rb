# encoding: utf-8
require_relative "../../spec_helper"
require "app/commands/stats/hotthreads_command"
require "app/commands/stats/memory_command"

describe "JVM stats" do

  describe LogStash::Api::HotThreadsCommand do

    let(:agent) { double("agent") }

    before(:each) do
      allow(agent).to receive(:node_name).and_return("foo")
      expect_any_instance_of(LogStash::Api::Service).to receive(:agent).and_return(agent)
      expect(subject).to receive(:uptime).and_return(10).at_least(:once)
    end

    context "#schema" do
      let(:report) { subject.run }

      it "return hot threads information" do
        expect(report.to_s).not_to be_empty
      end

    end
  end

  describe LogStash::Api::JvmMemoryCommand do

    context "#schema" do

      let(:report) { subject.run }

      it "return hot threads information" do
        expect(report).not_to be_empty
      end

      it "return heap information" do
        expect(report.keys).to include(:heap_used_in_bytes)
      end

      it "return non heap information" do
        expect(report.keys).to include(:non_heap_used_in_bytes)
      end

    end
  end
end
