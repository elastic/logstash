# encoding: utf-8
require "spec_helper"
require "logstash/runner"
require "stud/task"

class NullRunner
  def run(args); end
end

describe LogStash::Runner do

  subject { LogStash::Runner }
  let(:channel) { Cabin::Channel.new }

  before :each do
    allow(Cabin::Channel).to receive(:get).with(LogStash).and_return(channel)
  end

  describe "argument parsing" do

    before do
      #subject.configure # setup_agent requires this to give it logging
      #subject.setup_agent
    end

    subject { LogStash::Runner.new("") }
    context "when -e is given" do

      let(:args) { ["-e", ""] }
      let(:agent) { double("agent") }
      let(:agent_logger) { double("agent logger") }

      before do
        allow(agent).to receive(:logger=).with(anything)
      end

      it "should execute the agent" do
        expect(subject).to receive(:create_agent).and_return(agent)
        expect(agent).to receive(:execute).once
        subject.run(args)
      end
    end

    context "with no arguments" do
      let(:args) { [] }
      it "should show help" do
        expect(channel).to receive(:warn).once
        expect(channel).to receive(:fatal).once
        expect(subject).to receive(:show_short_help).once
        subject.run(args)
      end
    end
  end

  context "--agent" do
    class DummyAgent < LogStash::Agent; end

    let(:agent_name) { "testagent" }
    let(:dummy_agent_class) { DummyAgentClass }
    subject { LogStash::Runner.new("") }

    before do
      LogStash::AgentPluginManager.register(agent_name, DummyAgent)
      allow(subject).to receive(:execute) # stub this out to reduce test work/output
      subject.run(["-a", "testagent", "-e" "input {} output {}"])
    end

    it "should set the proper agent" do
      expect(subject.agent_class).to eql(DummyAgent)
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
      expect{subject.configure_plugin_paths(single_path)}.to raise_error(LogStash::ConfigurationError)
    end

    it "should add multiple valid dir path to the environment" do
      expect(File).to receive(:directory?).exactly(multiple_paths.size).times.and_return(true)
      multiple_paths.each{|path| expect(LogStash::Environment).to receive(:add_plugin_path).with(path)}
      subject.configure_plugin_paths(multiple_paths)
    end
  end
end
