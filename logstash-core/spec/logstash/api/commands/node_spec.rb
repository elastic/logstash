# encoding: utf-8
require "spec_helper"

describe LogStash::Api::Commands::Node do
  include_context "api setup"

  let(:report_method) { :all }
  let(:pipeline_id) { nil }
  let(:opts) { {} }
  let(:mocked_vertex) {{:config_name=>"elasticsearch",
                       :plugin_type=>"output",
                       :meta=>{
                         :source=>{
                           :protocol=>"str",
                           :id=>"pipeline",
                           :line=>1,
                           :column=>64
                         }
                       },
                       :id=>"2d2270426a2e8d7976b972b6a5318624331fa0d39fa3f903d2f3490e58a7d25a",
                       :explicit_id=>false,
                       :type=>"plugin"}
                  }
  subject(:report) do
    factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.new(@agent))
    if report_method == :pipelines
      factory.build(:node).send(report_method, opts)
    elsif report_method == :pipeline
      factory.build(:node).send(report_method, pipeline_id, opts)
    elsif report_method == :decorate_with_cluster_uuids
      factory.build(:node).send(report_method, mocked_vertex)
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
        # :dead_letter_queue_path is nil in tests
        # so it is ignored
      )
    end
  end

  describe "#pipeline?opts" do
    let(:report_method) { :pipeline }
    let(:pipeline_id) { "main" }
    let(:opts) { { :graph=>true } }
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
        # Be sure we display a graph when we set the option to
        :graph
      )
    end
  end

  describe "#os" do
    let(:report_method) { :os }
    it "check_keys" do
      expect(report.keys).to include(
        :name,
        :arch,
        :version,
        :available_processors
      )
    end
  end

  describe "#jvm" do
    let(:report_method) { :jvm }
    it "check_keys" do
      expect(report.keys).to include(
        :pid,
        :version,
        :vm_version,
        :vm_vendor,
        :vm_name,
        :start_time_in_millis,
        :mem,
        :gc_collectors
      )
    expect(report[:mem].keys).to include(
      :heap_init_in_bytes,
      :heap_max_in_bytes,
      :non_heap_init_in_bytes,
      :non_heap_max_in_bytes
    )
    end
  end
  describe "#decorate_with_cluster_uuid does not mutate" do
    let(:report_method) { :decorate_with_cluster_uuids }
    it "check keys" do
      expect(report.keys).to include(
        :config_name,
        :plugin_type,
        :meta,
        :id,
        :explicit_id,
        :type
      )
    end
  end


end
