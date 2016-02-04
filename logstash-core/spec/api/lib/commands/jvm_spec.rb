# encoding: utf-8
require_relative "../../spec_helper"
require "app/stats/hotthreads_command"
require "app/stats/memory_command"

describe "JVM stats" do

  describe LogStash::Api::HotThreadsCommand do

    context "#schema" do
      let(:report) { subject.run }

      it "return hot threads information" do
        expect(report).not_to be_empty
      end

    end
  end

  describe LogStash::Api::JvmMemoryCommand do


    context "#schema" do

      let(:service) { double("snapshot-service") }

      subject { described_class.new(service) }

      let(:stats) do
        read_fixture("memory.json")
      end

      before(:each) do
        allow(service).to receive(:get).with(:jvm_memory_stats).and_return(stats)
      end


      let(:report) do
        subject.run
      end

      it "return hot threads information" do
        expect(report).not_to be_empty
      end

      it "return heap information" do
        expect(report.keys).to include(:heap)
      end

      it "return non heap information" do
        expect(report.keys).to include(:non_heap)
      end

    end
  end


end
