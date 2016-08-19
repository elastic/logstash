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
    allow(channel).to receive(:subscribe).with(any_args)
    allow(channel).to receive(:log) {}
    allow(LogStash::ShutdownWatcher).to receive(:logger).and_return(channel)
  end

  after :each do
    LogStash::SETTINGS.reset
  end

  after :all do
    LogStash::ShutdownWatcher.logger = nil
  end

  describe "argument precedence" do
    let(:config) { "input {} output {}" }
    let(:cli_args) { ["-e", config, "-w", "20"] }
    let(:settings_yml_hash) { { "pipeline.workers" => 2 } }

    before :each do
      allow(LogStash::SETTINGS).to receive(:read_yaml).and_return(settings_yml_hash)
    end

    after :each do
      LogStash::SETTINGS.reset
    end

    it "favors the last occurence of an option" do
      expect(LogStash::Agent).to receive(:new) do |settings|
        expect(settings.get("config.string")).to eq(config)
        expect(settings.get("pipeline.workers")).to eq(20)
      end
      subject.run("bin/logstash", cli_args)
    end
  end

  describe "argument parsing" do
    subject { LogStash::Runner.new("") }
    before :each do
      allow(Cabin::Channel.get(LogStash)).to receive(:terminal)
    end
    context "when -e is given" do

      let(:args) { ["-e", "input {} output {}"] }
      let(:agent) { double("agent") }

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

      before(:each) do
        allow(LogStash::Util::JavaVersion).to receive(:warn_on_bad_java_version)
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

  describe "--log.format=json" do
    subject { LogStash::Runner.new("") }
    let(:logfile) { Stud::Temporary.file }
    let(:args) { [ "--log.format", "json", "-l", logfile.path, "-e", "input {} output{}" ] }

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

  describe "--config.test_and_exit" do
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

    context "when :http.host is defined by the user" do
      it "should pass the value to the webserver" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.set?("http.host")).to be(true)
          expect(settings.get("http.host")).to eq("localhost")
        end

        args = ["--http.host", "localhost", "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    context "when :http.host is not defined by the user" do
      it "should pass the value to the webserver" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.set?("http.host")).to be_falsey
          expect(settings.get("http.host")).to eq("127.0.0.1")
        end

        args = ["-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    context "when :http.port is defined by the user" do
      it "should pass a single value to the webserver" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.set?("http.port")).to be(true)
          expect(settings.get("http.port")).to eq(10000..10000)
        end

        args = ["--http.port", "10000", "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end

      it "should pass a range value to the webserver" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.set?("http.port")).to be(true)
          expect(settings.get("http.port")).to eq(10000..20000)
        end

        args = ["--http.port", "10000-20000", "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    context "when no :http.port is not defined by the user" do
      it "should use the default settings" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.set?("http.port")).to be_falsey
          expect(settings.get("http.port")).to eq(9600..9700)
        end

        args = ["-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    context "when :pipeline_workers is not defined by the user" do
      it "should not pass the value to the pipeline" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.set?("pipeline.workers")).to be(false)
        end
        args = ["-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    context "when :pipeline_workers flag is passed without a value" do
      it "should raise an error" do
        args = ["-e", pipeline_string, "-w"]
        expect { subject.run("bin/logstash", args) }.to raise_error
      end
    end

    context "when :pipeline_workers is defined by the user" do
      it "should pass the value to the pipeline" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.set?("pipeline.workers")).to be(true)
          expect(settings.get("pipeline.workers")).to be(2)
        end

        args = ["-w", "2", "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    describe "config.debug" do
      it "should set 'config.debug' to false by default" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.get("config.debug")).to eq(false)
        end
        args = ["--log.level", "debug", "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end

      it "should allow overriding config.debug" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.get("config.debug")).to eq(true)
        end
        args = ["--log.level", "debug", "--config.debug",  "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end
  end

  describe "--log.level" do
    before :each do
      allow_any_instance_of(subject).to receive(:show_version)
    end
    context "when not set" do
      it "should set log level to warn" do
        args = ["--version"]
        subject.run("bin/logstash", args)
        expect(channel.level).to eq(:warn)
      end
    end
    context "when setting to debug" do
      it "should set log level to debug" do
        args = ["--log.level", "debug",  "--version"]
        subject.run("bin/logstash", args)
        expect(channel.level).to eq(:debug)
      end
    end
    context "when setting to verbose" do
      it "should set log level to info" do
        args = ["--log.level", "verbose",  "--version"]
        subject.run("bin/logstash", args)
        expect(channel.level).to eq(:info)
      end
    end
    context "when setting to quiet" do
      it "should set log level to error" do
        args = ["--log.level", "quiet",  "--version"]
        subject.run("bin/logstash", args)
        expect(channel.level).to eq(:error)
      end
    end
  end

  describe "path.settings" do
    subject { LogStash::Runner.new("") }
    context "if does not exist" do
      let(:args) { ["--path.settings", "/tmp/a/a/a/a", "-e", "input {} output {}"] }

      it "should terminate logstash" do
        expect(subject.run(args)).to eq(1)
      end

      context "but if --help is passed" do
        let(:args) { ["--path.settings", "/tmp/a/a/a/a", "--help"] }

        it "should show help" do
          expect { subject.run(args) }.to raise_error(Clamp::HelpWanted)
        end
      end
    end
  end
end
