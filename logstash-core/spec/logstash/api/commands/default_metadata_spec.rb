# encoding: utf-8
require "spec_helper"

describe LogStash::Api::Commands::DefaultMetadata do
  include_context "api setup"

  let(:report_method) { :all }
  subject(:report) do
    factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.new(@agent))
    factory.build(:default_metadata).send(report_method)
  end

  let(:report_class) { described_class }

  describe "#plugins_stats_report" do
    let(:report_method) { :all }
    # Enforce just the structure
    it "check keys" do
      expect(report.keys).to include(
        :host,
        :version,
        :http_address,
        :id,
        :name,
        :ephemeral_id,
        :status,
        :snapshot,
        :pipeline
      )
      expect(report[:pipeline].keys).to include(
        :workers,
        :batch_size,
        :batch_delay,
      )
    end
  end
end
