# encoding: utf-8
require 'spec_helper'
require 'stud/temporary'

describe LogStash::Agent do

  let(:logger) { double("logger") }
  let(:agent_args) { { :logger => logger } }
  subject { LogStash::Agent.new(agent_args) }

  before :each do
    [:info, :warn, :error, :fatal, :debug].each do |level|
      allow(logger).to receive(level)
    end
    [:info?, :warn?, :error?, :fatal?, :debug?].each do |level|
      allow(logger).to receive(level)
    end
  end

  describe "register_pipeline" do
    let(:pipeline_id) { "main" }
    let(:settings) { {
      :config_string => "input { } filter { } output { }",
      :pipeline_workers => 4
    } }

    let(:agent_args) { {
      :logger => logger,
      :auto_reload => false,
      :reload_interval => 0.01
    } }

    it "should delegate settings to new pipeline" do
      expect(LogStash::Pipeline).to receive(:new).with(settings[:config_string], hash_including(settings))
      subject.register_pipeline(pipeline_id, settings)
    end
  end

  describe "#execute" do
    let(:sample_config) { "input { generator { count => 100000 } } output { stdout { } }" }
    let(:config_file) { Stud::Temporary.pathname }

    before :each do
      File.open(config_file, "w") {|f| f.puts sample_config }
    end

    after :each do
      File.unlink(config_file)
    end

    context "when auto_reload is false" do
      let(:agent_args) { { :logger => logger, :auto_reload => false, :reload_interval => 0.01, :config_path => config_file } }

      before :each do
        allow(subject).to receive(:sleep)
        allow(subject).to receive(:clean_state?).and_return(false)
        allow(subject).to receive(:running_pipelines?).and_return(true)
      end

      context "if state is clean" do
        it "should not reload_state!" do
          expect(subject).to_not receive(:reload_state!)
          t = Thread.new { subject.execute }
          sleep 0.1
          Stud.stop!(t)
          t.join
        end
      end
    end

    context "when auto_reload is true" do
      let(:agent_args) { { :logger => logger, :auto_reload => true, :reload_interval => 0.01 } }
      context "if state is clean" do
        it "should periodically reload_state" do
          allow(subject).to receive(:clean_state?).and_return(false)
          expect(subject).to receive(:reload_state!).at_least(3).times
          t = Thread.new { subject.execute }
          sleep 0.1
          Stud.stop!(t)
          t.join
        end
      end
    end
  end

  describe "#reload_state!" do
    let(:pipeline_id) { "main" }
    let(:first_pipeline_config) { "input { } filter { } output { }" }
    let(:second_pipeline_config) { "input { generator {} } filter { } output { }" }
    let(:pipeline_settings) { {
      :config_string => first_pipeline_config,
      :pipeline_workers => 4
    } }

    before(:each) do
      subject.register_pipeline(pipeline_id, pipeline_settings)
    end

    context "when fetching a new state" do
      it "upgrades the state" do
        expect(subject).to receive(:fetch_config).and_return(second_pipeline_config)
        expect(subject).to receive(:upgrade_pipeline).with(pipeline_id, kind_of(LogStash::Pipeline))
        subject.send(:reload_state!)
      end
    end
    context "when fetching the same state" do
      it "doesn't upgrade the state" do
        expect(subject).to receive(:fetch_config).and_return(first_pipeline_config)
        expect(subject).to_not receive(:upgrade_pipeline)
        subject.send(:reload_state!)
      end
    end
  end

  describe "#upgrade_pipeline" do
    let(:pipeline_id) { "main" }
    let(:pipeline_config) { "input { } filter { } output { }" }
    let(:pipeline_settings) { {
      :config_string => pipeline_config,
      :pipeline_workers => 4
    } }
    let(:new_pipeline_config) { "input { generator {} } output { }" }

    before(:each) do
      subject.register_pipeline(pipeline_id, pipeline_settings)
    end

    context "when the upgrade fails" do
      before :each do
        allow(subject).to receive(:fetch_config).and_return(new_pipeline_config)
        allow(subject).to receive(:create_pipeline).and_return(nil)
        allow(subject).to receive(:stop_pipeline)
      end

      it "leaves the state untouched" do
        subject.send(:reload_state!)
        expect(subject.pipelines[pipeline_id].config_str).to eq(pipeline_config)
      end

      context "and current state is empty" do
        it "should not start a pipeline" do
          expect(subject).to_not receive(:start_pipeline)
          subject.send(:reload_state!)
        end
      end
    end

    context "when the upgrade succeeds" do
      let(:new_config) { "input { generator { count => 1 } } output { }" }
      before :each do
        allow(subject).to receive(:fetch_config).and_return(new_config)
        allow(subject).to receive(:stop_pipeline)
      end
      it "updates the state" do
        subject.send(:reload_state!)
        expect(subject.pipelines[pipeline_id].config_str).to eq(new_config)
      end
      it "starts the pipeline" do
        expect(subject).to receive(:stop_pipeline)
        expect(subject).to receive(:start_pipeline)
        subject.send(:reload_state!)
      end
    end
  end

  describe "#fetch_config" do
    let(:file_config) { "input { generator { count => 100 } } output { stdout { } }" }
    let(:cli_config) { "filter { drop { } } " }
    let(:tmp_config_path) { Stud::Temporary.pathname }
    let(:agent_args) { { :logger => logger, :config_string => "filter { drop { } } ", :config_path => tmp_config_path } }

    before :each do
      IO.write(tmp_config_path, file_config)
    end

    after :each do
      File.unlink(tmp_config_path)
    end

    it "should join the config string and config path content" do
      fetched_config = subject.send(:fetch_config, tmp_config_path, cli_config)
      expect(fetched_config.strip).to eq(cli_config + IO.read(tmp_config_path))
    end

  end
end
