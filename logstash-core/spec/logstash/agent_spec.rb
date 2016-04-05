# encoding: utf-8
require 'spec_helper'

describe LogStash::Agent do
  subject { LogStash::Agent.new('') }
  let(:dummy_config) { 'input {}' }

  context "when loading the configuration" do
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

        before { expect(Net::HTTP).to receive(:get) { dummy_config } }
        it 'works with http' do
          expect(subject.load_config(path)).to eq("#{dummy_config}\n")
        end
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
      expect{subject.configure_plugin_paths(single_path)}.to raise_error(LogStash::ConfigurationError)
    end

    it "should add multiple valid dir path to the environment" do
      expect(File).to receive(:directory?).exactly(multiple_paths.size).times.and_return(true)
      multiple_paths.each{|path| expect(LogStash::Environment).to receive(:add_plugin_path).with(path)}
      subject.configure_plugin_paths(multiple_paths)
    end
  end

  describe "debug_config" do
    let(:pipeline_string) { "input {} output {}" }
    let(:pipeline) { double("pipeline") }

    before(:each) do
      allow(pipeline).to receive(:run)
    end
    it "should set 'debug_config' to false by default" do
      expect(LogStash::Pipeline).to receive(:new).
        with(anything,hash_including(:debug_config => false)).
        and_return(pipeline)
      args = ["--debug", "-e", pipeline_string]
      subject.run(args)
    end

    it "should allow overriding debug_config" do
      expect(LogStash::Pipeline).to receive(:new).
        with(anything, hash_including(:debug_config => true))
        .and_return(pipeline)
      args = ["--debug", "--debug-config",  "-e", pipeline_string]
      subject.run(args)
    end
  end
end
