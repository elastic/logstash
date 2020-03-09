# encoding: utf-8
require "spec_helper"

describe LogStash::Api::Commands::Stats do
  include_context "api setup"

  let(:report_method) { :run }
  let(:extended_pipeline) { nil }
  let(:opts) { {} }
  subject(:report) do
    factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.new(@agent))
    if extended_pipeline
      factory.build(:stats).send(report_method, "main", extended_pipeline, opts)
    else
      factory.build(:stats).send(report_method)
    end
  end

  let(:report_class) { described_class }

  describe "#plugins_stats_report" do
    let(:report_method) { :plugins_stats_report }
    # Enforce just the structure
    let(:extended_pipeline) {
      {
      :queue => "fake_queue",
      :hash => "fake_hash",
      :ephemeral_id => "fake_epehemeral_id",
      :vertices => "fake_vertices"
      }
    }
    # TODO pass in a real sample vertex
#    let(:opts) {
#      {
#        :vertices => "fake vertices"
#      }
#    }
    it "check keys" do
      expect(report.keys).to include(
        :queue,
        :hash,
        :ephemeral_id,
        # TODO re-add vertices -- see above
#        :vertices
      )
    end
  end

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
    it "returns information on existing pipeline" do
      expect(report.keys).to include(:main)
    end
    context "for each pipeline" do
      it "returns information on pipeline" do
        expect(report[:main].keys).to include(
          :events,
          :plugins,
          :reloads,
          :queue,
        )
      end
      it "returns event information" do
        expect(report[:main][:events].keys).to include(
          :in,
          :filtered,
          :duration_in_millis,
          :out,
          :queue_push_duration_in_millis
        )
      end
    end
    context "when using multiple pipelines" do
      before(:each) do
        expect(LogStash::Config::PipelinesInfo).to receive(:format_pipelines_info).and_return([
          {"id" => :main},
          {"id" => :secondary},
        ])
      end
      it "contains metrics for all pipelines" do
        expect(report.keys).to include(:main, :secondary)
      end
    end
  end
end
