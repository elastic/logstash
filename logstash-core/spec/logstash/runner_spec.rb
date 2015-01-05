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

    subject { LogStash::Runner.new("") }
    context "when -e is given" do

      let(:args) { ["-e", ""] }

      it "should execute the agent" do
        expect(subject.agent).to receive(:add_pipeline).once
        expect(subject.agent).to receive(:execute).once
        subject.run(args)
      end
    end

    context "with no arguments" do
      let(:args) { [] }
      it "should show help" do
        expect(subject).to receive(:show_short_help).once
        expect(channel).to receive(:fatal).once
        expect(channel).to receive(:warn).once
        subject.run(args)
      end
    end
  end

  context "when loading the configuration" do
    subject { LogStash::Runner.new("") }
    context "when local" do
      before { expect(subject).to receive(:local_config).with(path) }

      context "unix" do
        let(:path) { './test.conf' }
        it 'works with relative path' do
          subject.load_config(path)
        end
      end

      context "windows" do
        let(:path) { '.\test.conf' }
        it 'work with relative windows path' do
          subject.load_config(path)
        end
      end
    end

    context "when remote" do
      context 'supported scheme' do
        let(:path) { "http://test.local/superconfig.conf" }
        let(:dummy_config) { 'input {}' }

        before { expect(Net::HTTP).to receive(:get) { dummy_config } }
        it 'works with http' do
          expect(subject.load_config(path)).to eq("#{dummy_config}\n")
        end
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
      expect{subject.configure_plugin_paths(single_path)}.to raise_error(LogStash::ConfigurationError)
    end

    it "should add multiple valid dir path to the environment" do
      expect(File).to receive(:directory?).exactly(multiple_paths.size).times.and_return(true)
      multiple_paths.each{|path| expect(LogStash::Environment).to receive(:add_plugin_path).with(path)}
      subject.configure_plugin_paths(multiple_paths)
    end
  end
end
