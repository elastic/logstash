# encoding: utf-8
require "spec_helper"
require "logstash/runner"
require "stud/task"
require "stud/trap"

class NullRunner
  def run(args); end
end

describe LogStash::Runner do

  let(:channel) { Cabin::Channel.new }

  before :each do
    allow(Cabin::Channel).to receive(:get).with(LogStash).and_return(channel)
  end


  context "argument parsing" do
    it "should run agent" do
      expect(Stud::Task).to receive(:new).once.and_return(nil)
      args = ["agent", "-e", ""]
      expect(subject.run(args)).to eq(nil)
    end

    it "should run agent help" do
      expect(subject).to receive(:show_help).once.and_return(nil)
      args = ["agent", "-h"]
      expect(subject.run(args).wait).to eq(0)
    end

    it "should show help with no arguments" do
      expect($stderr).to receive(:puts).once.and_return("No command given")
      expect($stderr).to receive(:puts).once
      args = []
      expect(subject.run(args).wait).to eq(1)
    end

    it "should show help for unknown commands" do
      expect($stderr).to receive(:puts).once.and_return("No such command welp")
      expect($stderr).to receive(:puts).once
      args = ["welp"]
      expect(subject.run(args).wait).to eq(1)
    end
  end

  context "--auto-reload" do
    context "when -f is not given" do

      let(:args) { ["agent", "-r", "-e", "input {} output {}"] }

      it "should exit immediately" do
        expect(subject.run(args).wait).to eq(1)
      end
    end
  end

end
