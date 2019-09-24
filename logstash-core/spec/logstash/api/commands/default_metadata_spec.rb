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

  after :each do
    LogStash::SETTINGS.register(LogStash::Setting::Boolean.new("xpack.monitoring.enabled", false)) unless LogStash::SETTINGS.registered?("xpack.monitoring.enabled")
    LogStash::SETTINGS.reset
  end

  describe "#plugins_stats_report" do
    let(:report_method) { :all }
    # Enforce just the structure
    it "check monitoring" do
      LogStash::SETTINGS.set_value("xpack.monitoring.enabled", true)
      expect(report.keys).to include(
        :monitoring
        )
    end
    it "check monitoring does not appear when not enabled" do
      LogStash::SETTINGS.set_value("xpack.monitoring.enabled", false)
      expect(report.keys).not_to include(
        :monitoring
        )
    end

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
