# encoding: utf-8
require "spec_helper"

describe LogStash::Api::Commands::Stats do
  include_context "api setup"

  let(:report_method) { :run }
  subject(:report) do
    factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.new(@agent))

    factory.build(:stats).send(report_method)
  end

  let(:report_class) { described_class }

  describe "#events" do
    let(:report_method) { :events }

    it "return events information" do
      expect(report.keys).to include(
        :in,
        :filtered,
        :out,
        :duration_in_millis,
        :queue_push_duration_in_millis)
    end
  end

  describe "#hot_threads" do
    let(:report_method) { :hot_threads }

    it "should return hot threads information as a string" do
      expect(report.to_s).to be_a(String)
    end

    it "should return hot threads info as a hash" do
      expect(report.to_hash).to be_a(Hash)
    end
  end

  describe "memory stats" do
    let(:report_method) { :memory }

    it "return hot threads information" do
      expect(report).not_to be_empty
    end

    it "return memory information" do
      expect(report.keys).to include(
        :heap_used_percent,
        :heap_committed_in_bytes,
        :heap_max_in_bytes,
        :heap_used_in_bytes,
        :non_heap_used_in_bytes,
        :non_heap_committed_in_bytes,
        :pools
      )
    end
  end

  describe "jvm stats" do
    let(:report_method) { :jvm }

    it "return jvm information" do
      expect(report.keys).to include(
        :threads,
        :mem,
        :gc,
        :uptime_in_millis
      )
      expect(report[:threads].keys).to include(
        :count,
        :peak_count
      )
    end
  end

  describe "reloads stats" do
    let(:report_method) { :reloads }

    it "return reloads information" do
      expect(report.keys).to include(
      :successes,
      :failures,
      )
    end
  end

  describe "pipeline stats" do
    let(:report_method) { :pipeline }

    it "returns pipelines information" do
      expect(report.keys).to include (
        :main
      )
      expect(report[:main].keys).to include(
        :events,
        :plugins,
        :reloads,
        :queue,
        :hash,
        :ephemeral_id
      )
      expect(report[:main][:events].keys).to include(
        :in,
        :filtered,
        :duration_in_millis,
        :out,
        :queue_push_duration_in_millis
      )
      expect(report[:main][:plugins].keys).to include(
        :inputs,
        :codecs,
        :filters,
        :outputs
      )
      for input in report[:main][:plugins][:inputs]
        expect(input.keys).to include(
          :id,
          :events
        )
      end
      for output in report[:main][:plugins][:outputs]
        expect(output.keys).to include(
          :id,
          :events
        )
      end
    end
  end



end
