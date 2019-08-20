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
      expect(report.keys).to include(:in, :filtered, :out)
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

    it "return heap information" do
      expect(report.keys).to include(:heap_used_in_bytes)
    end

    it "return non heap information" do
      expect(report.keys).to include(:non_heap_used_in_bytes)
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
