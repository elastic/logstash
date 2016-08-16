# encoding: utf-8
require 'spec_helper'
require 'stud/temporary'
require 'stud/task'

describe LogStash::Agent do

  let(:logger) { double("logger") }
  let(:agent_args) { [] }
  subject { LogStash::Agent.new("", "") }

  before :each do
    [:log, :info, :warn, :error, :fatal, :debug, :terminal].each do |level|
      allow(logger).to receive(level)
    end
    [:info?, :warn?, :error?, :fatal?, :debug?].each do |level|
      allow(logger).to receive(level)
    end
    allow(logger).to receive(:level=)
    allow(logger).to receive(:subscribe)
    subject.parse(agent_args)
    subject.instance_variable_set("@reload_interval", 0.01)
    subject.instance_variable_set("@logger", logger)
  end

  describe "register_pipeline" do
    let(:pipeline_id) { "main" }
    let(:config_string) { "input { } filter { } output { }" }
    let(:settings) { {
      :config_string => config_string,
      :pipeline_workers => 4
    } }

    it "should delegate settings to new pipeline" do
      expect(LogStash::Pipeline).to receive(:new).with(settings[:config_string], hash_including(settings))
      subject.register_pipeline(pipeline_id, settings)
    end
  end

  describe "#execute" do
    let(:sample_config) { "input { generator { count => 100000 } } output { }" }
    let(:config_file) { Stud::Temporary.pathname }

    before :each do
      File.open(config_file, "w") {|f| f.puts sample_config }
    end

    after :each do
      File.unlink(config_file)
    end

    context "when auto_reload is false" do
      let(:agent_args) { [ "--config", config_file] } #reload_interval => 0.01, :config_path => } }
      let(:pipeline_id) { "main" }
      let(:pipeline_settings) { { :config_path => config_file } }

      before(:each) do
        subject.register_pipeline(pipeline_id, pipeline_settings)
      end

      context "if state is clean" do
        before :each do
          allow(subject).to receive(:running_pipelines?).and_return(true)
          allow(subject).to receive(:sleep)
          allow(subject).to receive(:clean_state?).and_return(false)
        end

        it "should not reload_state!" do
          expect(subject).to_not receive(:reload_state!)
          t = Thread.new { subject.execute }
          sleep 0.01 until subject.running_pipelines? && subject.pipelines.values.first.ready?
          sleep 0.1
          Stud.stop!(t)
          t.join
        end
      end

      context "when calling reload_state!" do
        context "with a config that contains reload incompatible plugins" do
          let(:second_pipeline_config) { "input { stdin {} } filter { } output { }" }

          it "does not reload if new config contains reload incompatible plugins" do
            t = Thread.new { subject.execute }
            sleep 0.01 until subject.running_pipelines? && subject.pipelines.values.first.ready?
            expect(subject).to_not receive(:upgrade_pipeline)
            File.open(config_file, "w") { |f| f.puts second_pipeline_config }
            subject.send(:reload_state!)
            sleep 0.1
            Stud.stop!(t)
            t.join
          end
        end

        context "with a config that does not contain reload incompatible plugins" do
          let(:second_pipeline_config) { "input { generator { } } filter { } output { }" }

          it "does not reload if new config contains reload incompatible plugins" do
            t = Thread.new { subject.execute }
            sleep 0.01 until subject.running_pipelines? && subject.pipelines.values.first.ready?
            expect(subject).to receive(:upgrade_pipeline)
            File.open(config_file, "w") { |f| f.puts second_pipeline_config }
            subject.send(:reload_state!)
            sleep 0.1
            Stud.stop!(t)
            t.join
          end
        end
      end
    end

    context "when auto_reload is true" do
      let(:agent_args) { [ "--auto-reload", "--config", config_file] } #reload_interval => 0.01, :config_path => } }
      let(:pipeline_id) { "main" }
      let(:pipeline_settings) { { :config_path => config_file } }

      before(:each) do
        subject.register_pipeline(pipeline_id, pipeline_settings)
      end

      context "if state is clean" do
        it "should periodically reload_state" do
          expect(subject).to receive(:reload_state!).at_least(3).times
          t = Thread.new(subject) {|subject| subject.execute }
          sleep 0.01 until (subject.running_pipelines? && subject.pipelines.values.first.ready?)
          # now that the pipeline has started, give time for reload_state! to happen a few times
          sleep 0.1
          Stud.stop!(t)
          t.join
        end
      end

      context "when calling reload_state!" do
        context "with a config that contains reload incompatible plugins" do
          let(:second_pipeline_config) { "input { stdin {} } filter { } output { }" }

          it "does not reload if new config contains reload incompatible plugins" do
            t = Thread.new { subject.execute }
            sleep 0.01 until subject.running_pipelines? && subject.pipelines.values.first.ready?
            expect(subject).to_not receive(:upgrade_pipeline)
            File.open(config_file, "w") { |f| f.puts second_pipeline_config }
            sleep 0.1
            Stud.stop!(t)
            t.join
          end
        end

        context "with a config that does not contain reload incompatible plugins" do
          let(:second_pipeline_config) { "input { generator { } } filter { } output { }" }

          it "does not reload if new config contains reload incompatible plugins" do
            t = Thread.new { subject.execute }
            sleep 0.01 until subject.running_pipelines? && subject.pipelines.values.first.ready?
            expect(subject).to receive(:upgrade_pipeline).at_least(2).times
            File.open(config_file, "w") { |f| f.puts second_pipeline_config }
            sleep 0.1
            Stud.stop!(t)
            t.join
          end
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

  context "--pluginpath" do
    let(:single_path) { "/some/path" }
    let(:multiple_paths) { ["/some/path1", "/some/path2"] }

    it "should add single valid dir path to the environment" do
      expect(File).to receive(:directory?).and_return(true)
      expect(LogStash::Environment).to receive(:add_plugin_path).with(single_path)
      subject.configure_plugin_paths(single_path)
    end

    it "should fail with single invalid dir path" do
      expect(File).to receive(:directory?).and_return(false)
      expect(LogStash::Environment).not_to receive(:add_plugin_path)
      expect{subject.configure_plugin_paths(single_path)}.to raise_error(Clamp::UsageError)
    end

    it "should add multiple valid dir path to the environment" do
      expect(File).to receive(:directory?).exactly(multiple_paths.size).times.and_return(true)
      multiple_paths.each{|path| expect(LogStash::Environment).to receive(:add_plugin_path).with(path)}
      subject.configure_plugin_paths(multiple_paths)
    end
  end

  describe "#fetch_config" do
    let(:file_config) { "input { generator { count => 100 } } output { }" }
    let(:cli_config) { "filter { drop { } } " }
    let(:tmp_config_path) { Stud::Temporary.pathname }
    let(:agent_args) { [ "-e", "filter { drop { } } ", "-f", tmp_config_path ] }

    before :each do
      IO.write(tmp_config_path, file_config)
    end

    after :each do
      File.unlink(tmp_config_path)
    end

    it "should join the config string and config path content" do
      settings = { :config_path => tmp_config_path, :config_string => cli_config }
      fetched_config = subject.send(:fetch_config, settings)
      expect(fetched_config.strip).to eq(cli_config + IO.read(tmp_config_path))
    end
  end

  context "--pluginpath" do
    let(:single_path) { "/some/path" }
    let(:multiple_paths) { ["/some/path1", "/some/path2"] }

    it "should fail with single invalid dir path" do
      expect(File).to receive(:directory?).and_return(false)
      expect(LogStash::Environment).not_to receive(:add_plugin_path)
      expect{subject.configure_plugin_paths(single_path)}.to raise_error(Clamp::UsageError)
    end
  end

  describe "--config-test" do
    let(:cli_args) { ["-t", "-e", pipeline_string] }
    let(:pipeline_string) { "input { } filter { } output { }" }

    context "with a good configuration" do
      it "should exit successfuly" do
        expect(subject.run(cli_args)).to eq(0)
      end
    end

    context "with a bad configuration" do
      let(:pipeline_string) { "rlwekjhrewlqrkjh" }
      it "should fail by returning a bad exit code" do
        expect(subject.run(cli_args)).to eq(1)
      end
    end

    it "requests the config loader to format_config" do
      expect(subject.config_loader).to receive(:format_config)
      subject.run(cli_args)
    end
  end

  describe "pipeline settings" do
    let(:pipeline_string) { "input { stdin {} } output { stdout {} }" }
    let(:main_pipeline_settings) { { :pipeline_id => "main" } }
    let(:pipeline) { double("pipeline") }

    before(:each) do
      task = Stud::Task.new { 1 }
      allow(pipeline).to receive(:run).and_return(task)
      allow(pipeline).to receive(:shutdown)
    end

    context "when :pipeline_workers is not defined by the user" do
      it "should not pass the value to the pipeline" do
        expect(LogStash::Pipeline).to receive(:new).once.with(pipeline_string, hash_excluding(:pipeline_workers)).and_return(pipeline)
        args = ["-e", pipeline_string]
        subject.run(args)
      end
    end

    context "when :pipeline_workers is defined by the user" do
      it "should pass the value to the pipeline" do
        main_pipeline_settings[:pipeline_workers] = 2
        expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, hash_including(main_pipeline_settings)).and_return(pipeline)
        args = ["-w", "2", "-e", pipeline_string]
        subject.run(args)
      end
    end
  end

  describe "debug_config" do
    let(:pipeline_string) { "input {} output {}" }
    let(:pipeline) { double("pipeline") }

    it "should set 'debug_config' to false by default" do
      expect(LogStash::Pipeline).to receive(:new).and_return(pipeline)
      args = ["--debug", "-e", pipeline_string]
      subject.run(args)

      expect(subject.config_loader.debug_config).to be_falsey
    end

    it "should allow overriding debug_config" do
      expect(LogStash::Pipeline).to receive(:new).and_return(pipeline)
      args = ["--debug", "--debug-config",  "-e", pipeline_string]
      subject.run(args)

      expect(subject.config_loader.debug_config).to be_truthy
    end
  end

  describe "allow_env param passing to pipeline" do
    let(:pipeline_string) { "input {} output {}" }
    let(:pipeline) { double("pipeline") }

    it "should set 'allow_env' to false by default" do
      args = ["-e", pipeline_string]
      expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, hash_including(:allow_env => false)).and_return(pipeline)
      subject.run(args)
    end

    it "should support templating environment variables" do
      args = ["-e", pipeline_string, "--allow-env"]
      expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, hash_including(:allow_env => true)).and_return(pipeline)
      subject.run(args)
    end
  end

  describe "Environment variables in config" do
    let(:pipeline_id) { "main" }
    let(:pipeline_config) { "input { generator { message => '${FOO}-bar' } } filter { } output { }" }
    let(:pipeline_settings) { { :config_string => pipeline_config } }
    let(:pipeline) { double("pipeline") }

    context "when allow_env is false" do
      it "does not interpolate environment variables" do
        expect(subject).to receive(:fetch_config).and_return(pipeline_config)
        subject.register_pipeline(pipeline_id, pipeline_settings)
        expect(subject.pipelines[pipeline_id].inputs.first.message).to eq("${FOO}-bar")
      end
    end

    context "when allow_env is true" do
      before :each do
        @foo_content = ENV["FOO"]
        ENV["FOO"] = "foo"
        pipeline_settings.merge!(:allow_env => true)
      end

      after :each do
        ENV["FOO"] = @foo_content
      end

      it "doesn't upgrade the state" do
        expect(subject).to receive(:fetch_config).and_return(pipeline_config)
        subject.register_pipeline(pipeline_id, pipeline_settings)
        expect(subject.pipelines[pipeline_id].inputs.first.message).to eq("foo-bar")
      end
    end
  end
end

