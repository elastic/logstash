# encoding: utf-8
require_relative "../../spec_helper"

describe LogStash::Api::Commands::Stats do

  let(:report_method) { :run }
  subject(:report) { do_request { report_class.new.send(report_method) } }

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
end
