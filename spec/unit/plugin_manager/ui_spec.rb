# encoding: utf-8
require "pluginmanager/ui"
describe LogStash::PluginManager do
  it "set the a default ui" do
    expect(LogStash::PluginManager.ui).to be_kind_of(LogStash::PluginManager::Shell)
  end

  it "you can override the ui" do
    klass = Class.new
    LogStash::PluginManager.ui = klass
    expect(LogStash::PluginManager.ui).to be(klass)
    LogStash::PluginManager.ui = LogStash::PluginManager::Shell.new
  end
end

describe LogStash::PluginManager::Shell do
  let(:message) { "hello world" }

  [:info, :error, :warn].each do |level|
    context "Level: #{level}" do
      it "display the message to the user" do
        expect(subject).to receive(:puts).with(message)
        subject.send(level, message)
      end
    end
  end

  context "Debug" do
    context "when ENV['DEBUG'] is set" do
      before do
        @previous_value = ENV["DEBUG"]
        ENV["DEBUG"] = "1"
      end

      it "outputs the message" do
        expect(subject).to receive(:puts).with(message)
        subject.debug(message)
      end

      after do
        ENV["DEBUG"] = @previous_value
      end
    end

    context "when ENV['DEBUG'] is not set" do
      @previous_value = ENV["DEBUG"]
      ENV.delete("DEBUG")
    end

    it "doesn't outputs the message" do
      expect(subject).not_to receive(:puts).with(message)
      subject.debug(message)
    end

    after do
      ENV["DEBUG"] = @previous_value
    end
  end
end
