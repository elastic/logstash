# encoding: utf-8
require_relative "../../spec_helper"
require "app/commands/stats/hotthreads_command"
require "app/commands/stats/memory_command"

describe "JVM stats" do

  describe LogStash::Api::HotThreadsCommand do

    let(:report) do
      do_request { subject.run }
    end

    context "#schema" do
      it "return hot threads information" do
        report = do_request { subject.run }
        expect(report.to_s).not_to be_empty
      end

    end
  end

  describe LogStash::Api::JvmMemoryCommand do

    context "#schema" do

      let(:report) do
        do_request { subject.run }
      end

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
