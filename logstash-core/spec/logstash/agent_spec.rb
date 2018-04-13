# encoding: utf-8
require "spec_helper"
require "stud/temporary"
require "logstash/inputs/generator"
require "logstash/config/pipeline_config"
require "logstash/config/source/local"
require_relative "../support/mocks_classes"
require "fileutils"
require_relative "../support/helpers"
require_relative "../support/matchers"
require 'timeout'

java_import org.logstash.Timestamp

describe LogStash::Agent do
  let(:agent_settings) { mock_settings({}) }
  let(:agent_args) { {} }
  let(:pipeline_settings) { agent_settings.clone }
  let(:pipeline_args) { {} }
  let(:default_pipeline_id) { agent_settings.get("pipeline.id") }
  let(:config_string) { "input { } filter { } output { }" }
  let(:config_file) { Stud::Temporary.pathname }
  let(:config_file_txt) { config_string }
  let(:default_source_loader) do
    sl = LogStash::Config::SourceLoader.new
    sl.add_source(LogStash::Config::Source::Local.new(agent_settings))
    sl
  end
  let(:logger) { double("logger") }
  let(:timeout) {120} #seconds

  subject { LogStash::Agent.new(agent_settings, default_source_loader) }

  before :each do
    # This MUST run first, before `subject` is invoked to ensure clean state
    clear_data_dir

    File.open(config_file, "w") { |f| f.puts(config_file_txt) }

    agent_args.each do |key, value|
      agent_settings.set(key, value)
      pipeline_settings.set(key, value)
    end
    pipeline_args.each do |key, value|
      pipeline_settings.set(key, value)
    end
    allow(described_class).to receive(:logger).and_return(logger)
    [:debug, :info, :error, :fatal, :trace].each {|level| allow(logger).to receive(level) }
    [:debug?, :info?, :error?, :fatal?, :trace?].each {|level| allow(logger).to receive(level) }
  end

  after :each do
    subject.shutdown
    LogStash::SETTINGS.reset

    FileUtils.rm(config_file)
    FileUtils.rm_rf(subject.id_path)
  end

  it "fallback to hostname when no name is provided" do
    expect(LogStash::Agent.new(agent_settings, default_source_loader).name).to eq(Socket.gethostname)
  end

  describe "adding a new pipeline" do
    let(:agent_args) { { "config.string" => config_string } }

    it "should delegate settings to new pipeline" do
      expect(LogStash::JavaPipeline).to receive(:new) do |arg1, arg2|
        expect(arg1).to eq(config_string)
        expect(arg2.to_hash).to include(agent_args)
      end
      subject.converge_state_and_update
    end
  end

  describe "#id" do
    let(:id_file_data) { File.open(subject.id_path) {|f| f.read } }

    it "should return a UUID" do
      expect(subject.id).to be_a(String)
      expect(subject.id.size).to be > 0
    end

    it "should write out the persistent UUID" do
      expect(id_file_data).to eql(subject.id)
    end
  end

  describe "ephemeral_id" do
    it "create a ephemeral id at creation time" do
      expect(subject.ephemeral_id).to_not be_nil
    end
  end

  describe "#execute" do
    let(:config_string) { "input { generator { id => 'old'} } output { }" }
    let(:mock_config_pipeline) { mock_pipeline_config(:main, config_string, pipeline_settings) }

    let(:source_loader) { TestSourceLoader.new(mock_config_pipeline) }
    subject { described_class.new(agent_settings, source_loader) }

    before :each do
      allow(subject).to receive(:start_webserver).and_return(false)
      allow(subject).to receive(:stop_webserver).and_return(false)
    end

    context "when auto_reload is false" do
      let(:agent_settings) { mock_settings("config.reload.automatic" => false) }
      let(:agent_args) { { "path.config" => config_file } }

      context "if state is clean" do
        before :each do
          allow(subject).to receive(:running_user_defined_pipelines?).and_return(true)
          allow(subject).to receive(:clean_state?).and_return(false)
        end

        it "should not converge state more than once" do
          expect(subject).to receive(:converge_state_and_update).once
          t = Thread.new { subject.execute }

          Stud.stop!(t)
          t.join
          subject.shutdown
        end
      end

      context "when calling reloading a pipeline" do
        context "with a config that contains reload incompatible plugins" do
          let(:second_pipeline_config) { "input { stdin {} } filter { } output { }" }
          let(:mock_second_pipeline_config) { mock_pipeline_config(:main, second_pipeline_config, pipeline_settings) }

          let(:source_loader) { TestSequenceSourceLoader.new(mock_config_pipeline, mock_second_pipeline_config)}

          it "does not upgrade the new config" do
            t = Thread.new { subject.execute }
            Timeout.timeout(timeout) do
              sleep(0.01) until subject.running_pipelines? && subject.pipelines.values.first.ready?
            end
            expect(subject.converge_state_and_update).not_to be_a_successful_converge
            expect(subject).to have_running_pipeline?(mock_config_pipeline)

            Stud.stop!(t)
            t.join
            subject.shutdown
          end
        end

        context "with a config that does not contain reload incompatible plugins" do
          let(:second_pipeline_config) { "input { generator { } } filter { } output { }" }
          let(:mock_second_pipeline_config) { mock_pipeline_config(:main, second_pipeline_config, pipeline_settings) }

          let(:source_loader) { TestSequenceSourceLoader.new(mock_config_pipeline, mock_second_pipeline_config)}

          it "does upgrade the new config" do
            t = Thread.new { subject.execute }
            Timeout.timeout(timeout) do
              sleep(0.01) until subject.pipelines_count > 0 && subject.pipelines.values.first.ready?
            end

            expect(subject.converge_state_and_update).to be_a_successful_converge
            expect(subject).to have_running_pipeline?(mock_second_pipeline_config)

            Stud.stop!(t)
            t.join
            subject.shutdown
          end
        end

      end
      context "when calling reload_state!" do
        context "with a pipeline with auto reloading turned off" do
          let(:second_pipeline_config) { "input { generator { } } filter { } output { }" }
          let(:pipeline_args) { { "pipeline.reloadable" => false } }
          let(:mock_second_pipeline_config) { mock_pipeline_config(:main, second_pipeline_config, mock_settings(pipeline_args)) }

          let(:source_loader) { TestSequenceSourceLoader.new(mock_config_pipeline, mock_second_pipeline_config)}

          it "does not try to reload the pipeline" do
            t = Thread.new { subject.execute }
            Timeout.timeout(timeout) do
              sleep(0.01) until subject.running_pipelines? && subject.pipelines.values.first.running?
            end
            expect(subject.converge_state_and_update).not_to be_a_successful_converge
            expect(subject).to have_running_pipeline?(mock_config_pipeline)

            Stud.stop!(t)
            t.join
            subject.shutdown
          end
        end

        context "with a pipeline with auto reloading turned on" do
          let(:second_pipeline_config) { "input { generator { id => 'second' } } filter { } output { }" }
          let(:pipeline_args) { { "pipeline.reloadable" => true } }
          let(:mock_second_pipeline_config) { mock_pipeline_config(:main, second_pipeline_config, mock_settings(pipeline_args)) }
          let(:source_loader) { TestSequenceSourceLoader.new(mock_config_pipeline, mock_second_pipeline_config)}

          it "tries to reload the pipeline" do
            t = Thread.new { subject.execute }
            Timeout.timeout(timeout) do
              sleep(0.01) until subject.running_pipelines? && subject.pipelines.values.first.running?
            end

            expect(subject.converge_state_and_update).to be_a_successful_converge
            expect(subject).to have_running_pipeline?(mock_second_pipeline_config)

            Stud.stop!(t)
            t.join
            subject.shutdown
          end
        end
      end
    end
  end

  describe "Environment Variables In Configs" do
    let(:temporary_file) { Stud::Temporary.file.path }

    let(:pipeline_config) { "input { generator { message => '${FOO}-bar' count => 1 } } filter { } output { file { path => '#{temporary_file}' } }" }
    let(:agent_args) { {
      "config.reload.automatic" => false,
      "config.reload.interval" => "10ms",
      "config.string" => pipeline_config
    } }

    let(:source_loader) {
      TestSourceLoader.new(mock_pipeline_config(default_pipeline_id, pipeline_config))
    }

    subject { described_class.new(mock_settings(agent_args), source_loader) }

    after do
      subject.shutdown
    end

    context "environment variable templating" do
      before :each do
        @foo_content = ENV["FOO"]
        ENV["FOO"] = "foo"
      end

      after :each do
        ENV["FOO"] = @foo_content
      end

      it "are evaluated at plugins creation" do
        expect(subject.converge_state_and_update).to be_a_successful_converge

        # Since the pipeline is running in another threads
        # the content of the file wont be instant.
        Timeout.timeout(timeout) do
          sleep(0.01) until ::File.size(temporary_file) > 0
        end
        json_document = LogStash::Json.load(File.read(temporary_file).chomp)
        expect(json_document["message"]).to eq("foo-bar")
      end
    end
  end

  describe "#upgrade_pipeline" do
    let(:pipeline_config) { "input { generator {} } filter { } output { }" }
    let(:pipeline_args) { { "pipeline.workers" => 4 } }
    let(:mocked_pipeline_config) { mock_pipeline_config(default_pipeline_id, pipeline_config, mock_settings(pipeline_args))}

    let(:new_pipeline_config) { "input generator {} } output { }" }
    let(:mocked_new_pipeline_config) { mock_pipeline_config(default_pipeline_id, new_pipeline_config, mock_settings(pipeline_args))}
    let(:source_loader) { TestSequenceSourceLoader.new(mocked_pipeline_config, mocked_new_pipeline_config)}

    subject { described_class.new(agent_settings, source_loader) }

    before(:each) do
      # Run the initial config
      expect(subject.converge_state_and_update).to be_a_successful_converge
    end

    after(:each) do
      # new pipelines will be created part of the upgrade process so we need
      # to close any initialized pipelines
      subject.shutdown
    end

    context "when the upgrade fails" do
      it "leaves the state untouched" do
        expect(subject.converge_state_and_update).not_to be_a_successful_converge
        expect(subject.get_pipeline(default_pipeline_id).config_str).to eq(pipeline_config)
      end

      # TODO(ph): This valid?
      xcontext "and current state is empty" do
        it "should not start a pipeline" do
          expect(subject).to_not receive(:start_pipeline)
          subject.send(:"reload_pipeline!", default_pipeline_id)
        end
      end
    end

    context "when the upgrade succeeds" do
      let(:new_config) { "input { generator { id => 'abc' count => 1000000 } } output { }" }
      let(:mocked_new_pipeline_config) { mock_pipeline_config(default_pipeline_id, new_config, mock_settings(pipeline_args)) }

      it "updates the state" do
        expect(subject.converge_state_and_update).to be_a_successful_converge
        expect(subject.get_pipeline(default_pipeline_id).config_str).to eq(new_config)
      end

      it "starts the pipeline" do
        expect(subject.converge_state_and_update).to be_a_successful_converge
        expect(subject.get_pipeline(default_pipeline_id).running?).to be_truthy
      end
    end
  end

  context "#started_at" do
    it "return the start time when the agent is started" do
      expect(described_class::STARTED_AT).to be_kind_of(Time)
    end
  end

  context "#uptime" do
    it "return the number of milliseconds since start time" do
      expect(subject.uptime).to be >= 0
    end
  end

  context "metrics after config reloading" do

    let(:initial_generator_threshold) { 1000 }
    let(:original_config_output) { Stud::Temporary.pathname }
    let(:new_config_output) { Stud::Temporary.pathname }

    let(:config_file_txt) { "input { generator { count => #{initial_generator_threshold*2} } } output { file { path => '#{original_config_output}'} }" }

    let(:agent_args) do
      {
        "metric.collect" => true,
        "path.config" => config_file
      }
    end

    subject { described_class.new(agent_settings, default_source_loader) }

    let(:agent_thread) do
      # subject has to be called for the first time outside the thread because it could create a race condition
      # with subsequent subject calls
      s = subject
      Thread.new { s.execute }
    end

    before(:each) do
      @abort_on_exception = Thread.abort_on_exception
      Thread.abort_on_exception = true

      agent_thread

      # wait for some events to reach the dummy_output
      Timeout.timeout(timeout) do
        # wait for file existence otherwise it will raise exception on Windows
        sleep(0.1) until ::File.exist?(original_config_output)
        sleep(0.1) until IO.readlines(original_config_output).size > initial_generator_threshold
      end

      # write new config
      File.open(config_file, "w") { |f| f.write(new_config) }
    end

    after :each do
      begin
        Stud.stop!(agent_thread) rescue nil # it may be dead already
        agent_thread.join
        subject.shutdown

        FileUtils.rm(original_config_output)
        FileUtils.rm(new_config_output) if File.exist?(new_config_output)
      rescue
          #don't care about errors here.
      ensure
        Thread.abort_on_exception = @abort_on_exception
      end
    end

    context "when reloading a good config" do
      let(:new_config_generator_counter) { 500 }
      let(:new_config) { "input { generator { count => #{new_config_generator_counter} } } output { file { path => '#{new_config_output}'} }" }

      before :each do
        subject.converge_state_and_update
        Timeout.timeout(timeout) do
          # wait for file existence otherwise it will raise exception on Windows
          sleep(0.1) until ::File.exist?(new_config_output)
          sleep(0.1) while ::File.read(new_config_output).chomp.empty?
        end
        # ensure the converge_state_and_update method has updated metrics by
        # invoking the mutex
        subject.running_pipelines?
      end

      it "resets the pipeline metric collector" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:events][:in].value
        expect(value).to be <= new_config_generator_counter
      end

      it "does not reset the global event count" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/events")[:stats][:events][:in].value
        expect(value).to be > initial_generator_threshold
      end

      it "increases the successful reload count" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads][:successes].value
        expect(value).to eq(1)
        instance_value = snapshot.metric_store.get_with_path("/stats")[:stats][:reloads][:successes].value
        expect(instance_value).to eq(1)
      end

      it "does not set the failure reload timestamp" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads][:last_failure_timestamp].value
        expect(value).to be(nil)
      end

      it "sets the success reload timestamp" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads][:last_success_timestamp].value
        expect(value).to be_a(Timestamp)
      end

      it "does not set the last reload error" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads][:last_error].value
        expect(value).to be(nil)
      end
    end

    context "when reloading a bad config" do
      let(:new_config) { "input { generator { count => " }
      before(:each) { subject.converge_state_and_update }

      it "does not increase the successful reload count" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads][:successes].value
        expect(value).to eq(0)
      end

      it "does not set the successful reload timestamp" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads][:last_success_timestamp].value
        expect(value).to be(nil)
      end

      it "sets the failure reload timestamp" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads][:last_failure_timestamp].value
        expect(value).to be_a(Timestamp)
      end

      it "sets the last reload error" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads][:last_error].value
        expect(value).to be_a(Hash)
        expect(value).to include(:message, :backtrace)
      end

      it "increases the failed reload count" do
        snapshot = subject.metric.collector.snapshot_metric
        value = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads][:failures].value
        expect(value).to be > 0
      end
    end

    context "when reloading a config that raises exception on pipeline.run" do
      let(:new_config) { "input { generator { count => 10000 } } output { null {} }" }
      let(:agent_args) do
        {
          "config.reload.automatic" => false,
          "pipeline.batch.size" => 1,
          "metric.collect" => true,
          "path.config" => config_file
        }
      end

      class BrokenGenerator < LogStash::Inputs::Generator
        def register
          raise ArgumentError
        end
      end

      before :each do
        allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_return(BrokenGenerator)
      end

      it "does not increase the successful reload count" do
        expect { subject.converge_state_and_update }.to_not change {
          snapshot = subject.metric.collector.snapshot_metric
          reload_metrics = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads]
          reload_metrics[:successes].value
        }
      end

      it "increases the failures reload count" do
        expect { subject.converge_state_and_update }.to change {
          snapshot = subject.metric.collector.snapshot_metric
          reload_metrics = snapshot.metric_store.get_with_path("/stats/pipelines")[:stats][:pipelines][:main][:reloads]
          reload_metrics[:failures].value
        }.by(1)
      end
    end
  end
end
