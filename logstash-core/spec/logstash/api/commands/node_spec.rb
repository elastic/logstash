# encoding: utf-8
require "spec_helper"

describe LogStash::Api::Commands::Node do
  include_context "api setup"

  let(:report_method) { :all }
  let(:pipeline_id) { nil }
  subject(:report) do
    factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.new(@agent))
    if pipeline_id
      factory.build(:node).send(report_method, pipeline_id)
    else
      factory.build(:node).send(report_method)
    end
  end

  let(:report_class) { described_class }

  describe "#all" do
    let(:report_method) { :all }
    # Enforce just the structure
    it "check keys" do
      expect(report.keys).to include(
        :pipelines,
        :os,
        :jvm
      )
    end
  end


  describe "#pipeline" do
    let(:report_method) { :pipeline }
    let(:pipeline_id) { "main" }
    # Enforce just the structure
    it "check keys" do
      expect(report.keys).to include(
        :ephemeral_id,
        :hash,
        :workers,
        :batch_size,
        :batch_delay,
        :config_reload_automatic,
        :config_reload_interval,
        :dead_letter_queue_enabled,
        :dead_letter_queue_path
        # :dead_letter_queue_path is nil in tests
        # so it is ignored
      )
    end
  end
end
