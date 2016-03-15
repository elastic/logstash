# encoding: utf-8
require "spec_helper"
require "logstash/runner"
require "stud/task"
require "stud/trap"
require "stud/temporary"
require "logstash/util/java_version"
require "logstash/logging/json"
require "json"

class NullRunner
  def run(args); end
end

describe LogStash::Runner do

  subject { LogStash::Runner }
  let(:channel) { Cabin::Channel.new }

  before :each do
    allow(Cabin::Channel).to receive(:get).with(LogStash).and_return(channel)
    allow(channel).to receive(:subscribe).with(any_args).and_call_original
  end

  describe "argument parsing" do
    subject { LogStash::Runner.new("") }
    context "when -e is given" do

      let(:args) { ["-e", "input {} output {}"] }
      let(:agent) { double("agent") }
      let(:agent_logger) { double("agent logger") }

      before do
        allow(agent).to receive(:logger=).with(anything)
        allow(agent).to receive(:shutdown)
        allow(agent).to receive(:register_pipeline)
      end

      it "should execute the agent" do
        expect(subject).to receive(:create_agent).and_return(agent)
        expect(agent).to receive(:execute).once
        subject.run(args)
      end
    end

    context "with no arguments" do
      let(:args) { [] }
      let(:agent) { double("agent") }

      before(:each) do
        allow(LogStash::Agent).to receive(:new).and_return(agent)        
      end

      it "should show help" do
        expect($stderr).to receive(:puts).once
        expect(subject).to receive(:signal_usage_error).once.and_call_original
        expect(subject).to receive(:show_short_help).once
        subject.run(args)
      end
    end
  end

  context "--pluginpath" do
    subject { LogStash::Runner.new("") }
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

  context "--auto-reload" do
    subject { LogStash::Runner.new("") }
    context "when -f is not given" do

      let(:args) { ["-r", "-e", "input {} output {}"] }

      it "should exit immediately" do
        expect(subject).to receive(:signal_usage_error).and_call_original
        expect(subject).to receive(:show_short_help)
        expect(subject.run(args)).to eq(1)
      end
    end
  end

  context "--log-in-json" do
    subject { LogStash::Runner.new("") }
    let(:logfile) { Stud::Temporary.file }
    let(:args) { [ "--log-in-json", "-l", logfile.path, "-e", "input {} output{}" ] }

    after do
      logfile.close
      File.unlink(logfile.path)
    end

    before do
      expect(channel).to receive(:subscribe).with(kind_of(LogStash::Logging::JSON)).and_call_original
      subject.run(args)

      # Log file should have stuff in it.
      expect(logfile.stat.size).to be > 0
    end

    it "should log in valid json. One object per line." do
      logfile.each_line do |line|
        expect(line).not_to be_empty
        expect { JSON.parse(line) }.not_to raise_error
      end
    end
  end

  describe "--config-test" do
    subject { LogStash::Runner.new("") }
    let(:args) { ["-t", "-e", pipeline_string] }

    context "with a good configuration" do
      let(:pipeline_string) { "input { } filter { } output { }" }
      it "should exit successfuly" do
        expect(channel).to receive(:terminal)
        expect(subject.run(args)).to eq(0)
      end
    end

    context "with a bad configuration" do
      let(:pipeline_string) { "rlwekjhrewlqrkjh" }
      it "should fail by returning a bad exit code" do
        expect(channel).to receive(:fatal)
        expect(subject.run(args)).to eq(1)
      end
    end
  end
  describe "pipeline settings" do
    let(:pipeline_string) { "input { stdin {} } output { stdout {} }" }
    let(:main_pipeline_settings) { { :pipeline_id => "main" } }
    let(:pipeline) { double("pipeline") }

    before(:each) do
      allow_any_instance_of(LogStash::Agent).to receive(:execute).and_return(true)
      task = Stud::Task.new { 1 }
      allow(pipeline).to receive(:run).and_return(task)
      allow(pipeline).to receive(:shutdown)
    end

    context "when :pipeline_workers is not defined by the user" do
      it "should not pass the value to the pipeline" do
        expect(LogStash::Pipeline).to receive(:new).once.with(pipeline_string, hash_excluding(:pipeline_workers)).and_return(pipeline)

        args = ["-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    context "when :pipeline_workers is defined by the user" do
      it "should pass the value to the pipeline" do
        main_pipeline_settings[:pipeline_workers] = 2
        expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, hash_including(main_pipeline_settings)).and_return(pipeline)

        args = ["-w", "2", "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    describe "debug_config" do
      it "should set 'debug_config' to false by default" do
        expect(LogStash::Config::Loader).to receive(:new).with(anything, false).and_call_original
        expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, hash_including(:debug_config => false)).and_return(pipeline)
        args = ["--debug", "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end

      it "should allow overriding debug_config" do
        expect(LogStash::Config::Loader).to receive(:new).with(anything, true).and_call_original
        expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, hash_including(:debug_config => true)).and_return(pipeline)
        args = ["--debug", "--debug-config",  "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    context "when configuring environment variable support" do
      it "should set 'allow_env' to false by default" do
        args = ["-e", pipeline_string]
        expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, hash_including(:allow_env => false)).and_return(pipeline)
        subject.run("bin/logstash", args)
      end

      it "should support templating environment variables" do
        args = ["-e", pipeline_string, "--allow-env"]
        expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, hash_including(:allow_env => true)).and_return(pipeline)
        subject.run("bin/logstash", args)
      end
    end
  end
end
