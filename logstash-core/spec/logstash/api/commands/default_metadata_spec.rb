# encoding: utf-8
require "spec_helper"

describe LogStash::Api::Commands::DefaultMetadata do
  include_context "api setup"

  def registerIfNot(setting)
    LogStash::SETTINGS.register(setting) unless LogStash::SETTINGS.registered?(setting.name)
  end

  let(:report_method) { :all }
  subject(:report) do
    factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.new(@agent))
    factory.build(:default_metadata).send(report_method)
  end

  let(:report_class) { described_class }

  before :all do
    registerIfNot(LogStash::Setting::Boolean.new("xpack.monitoring.enabled", false))
    registerIfNot(LogStash::Setting::ArrayCoercible.new("xpack.monitoring.elasticsearch.hosts", String, [ "http://localhost:9200" ] ))
    registerIfNot(LogStash::Setting::NullableString.new("xpack.monitoring.elasticsearch.username", "logstash_TEST system"))
    registerIfNot(LogStash::Setting::NullableString.new("xpack.monitoring.elasticsearch.username", "logstash_TEST system"))
  end

  after :each do
    LogStash::SETTINGS.set_value("xpack.monitoring.enabled", false)
  end

  describe "#plugins_stats_report" do
    let(:report_method) { :all }

    # Enforce just the structure
    it "check monitoring exist when cluster_uuid has been defined" do
      LogStash::SETTINGS.set_value("monitoring.cluster_uuid", "cracking_cluster")
      expect(report.keys).to include(
        :monitoring
        )
    end

    it "check monitoring exist when monitoring is enabled" do
      LogStash::SETTINGS.set_value("xpack.monitoring.enabled", true)
      expect(report.keys).to include(
        :monitoring
        )
    end

    it "check monitoring does not appear when not enabled and nor cluster_uuid is defined" do
      LogStash::SETTINGS.set_value("xpack.monitoring.enabled", false)
      LogStash::SETTINGS.get_setting("monitoring.cluster_uuid").reset
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
