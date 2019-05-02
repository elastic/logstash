# encoding: utf-8
require "spec_helper"

describe LogStash::Api::Commands::Node do
  include_context "api setup"

  let(:report_method) { :run }
  subject(:report) do
    factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.new(@agent))
   
    factory.build(:node).send(report_method)
  end

  let(:report_class) { described_class }

  describe "#pipelines" do
    let(:report_method) { :pipelines }

    it "return all pipelines information" do
      expect(report.to_hash).to be_a(Hash)
    end

    it "all pipelines info generates graph" do
      expect(report[:main].keys).to include(:graph)
    end

    it "all pipelines info generates ephemeral id" do
      expect(report[:main].keys).to include(:ephemeral_id)
    end

    it "all pipelines info generates hash" do
      expect(report[:main].keys).to include(:hash)
    end

  end
end
