# encoding: utf-8
require "paquet/shell_ui"

describe Paquet::ShellUi do
  let(:message) { "hello world" }

  subject { described_class.new }

  context "when debug is on" do
    before :all do
      @debug = ENV["debug"]
      ENV["DEBUG"] = "1"
    end

    after :all do
      ENV["DEBUG"] = @debug
    end

    it "show the debug statement" do
      expect(subject).to receive(:puts).with("[DEBUG]: #{message}")
      subject.debug(message)
    end
  end

  context "not in debug" do
    before :all do
      @debug = ENV["debug"]
      ENV["DEBUG"] = nil
    end

    after :all do
      ENV["DEBUG"] = @debug
    end

    it "doesnt show the debug statement" do
      expect(subject).not_to receive(:puts).with("[DEBUG]: #{message}")
      subject.debug(message)
    end
  end
end
