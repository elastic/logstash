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
  end

  describe "#execute" do
    context "when auto_reload is false" do
      let(:agent_args) { { :logger => logger, :auto_reload => false, :reload_interval => 0.01 } }
      context "if state is clean" do
        it "should only reload_state once" do
          allow(subject).to receive(:sleep)
          expect(subject).to receive(:reload_state!).exactly(:once)
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
          expect(subject).to receive(:reload_state!).at_least(:twice)
          t = Thread.new { subject.execute }
          sleep 0.1
          Stud.stop!(t)
          t.join
        end
      end
    end
  end

  describe "#reload_state!" do
    context "when fetching a new state" do
      it "upgrades the state" do
        allow(subject).to receive(:fetch_state).and_return("input { plugin {} } output { plugin {} }")
        expect(subject).to receive(:upgrade_state)
        subject.send(:reload_state!)
      end
    end
    context "when fetching the same state" do
      it "doesn't upgrade the state" do
        allow(subject).to receive(:fetch_state).and_return("")
        expect(subject).to_not receive(:upgrade_state)
        subject.send(:reload_state!)
      end
    end
  end

  describe "#upgrade_state" do
    context "when the upgrade fails" do
      before :each do
        allow(subject).to receive(:fetch_state).and_return("input { plugin {} } output { plugin {} }")
        allow(subject).to receive(:add_pipeline).and_raise(StandardError)
      end
      it "leaves the state untouched" do
        subject.send(:reload_state!)
        expect(subject.state).to eq("")
      end
      context "and current state is empty" do
        it "should not start a pipeline" do
          expect(subject).to_not receive(:start_pipeline)
          subject.send(:reload_state!)
        end
      end
    end

    context "when the upgrade succeeds" do
      let(:new_state) { "input { generator { count => 1 } } output { stdout {} }" }
      before :each do
        allow(subject).to receive(:fetch_state).and_return(new_state)
        allow(subject).to receive(:add_pipeline)
      end
      it "updates the state" do
        subject.send(:reload_state!)
        expect(subject.state).to eq(new_state)
      end
      it "starts the pipeline" do
        expect(subject).to receive(:start_pipeline)
        subject.send(:reload_state!)
      end
    end
  end

  describe "#fetch_state" do
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
      expect(subject.send(:fetch_state).strip).to eq(cli_config + IO.read(tmp_config_path))
    end

  end

  def make_agent(options={})
    LogStash::Agent.new(Cabin::Channel.get(), options)
  end

  context "#node_name" do
    let(:hostname) { "the-logstash" }

    before do
      allow(Socket).to receive(:gethostname).and_return(hostname)
    end

    it "fallback to hostname when no name is provided" do
      expect(make_agent.node_name).to be(hostname)
    end

    it "uses the user provided name" do
      expect(make_agent({ :node_name => "a-name" }).node_name).to eq("a-name")
    end
  end

  context "#node_uuid" do
    it "create a unique uuid between agent instances" do
      expect(make_agent.node_uuid).not_to be(make_agent.node_uuid)
    end
  end
end
