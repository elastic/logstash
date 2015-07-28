require "spec_helper"
require "logstash/runner"
require "stud/task"
require "logstash/agent"

class NullRunner
  def run(args); end
end

describe LogStash::Runner do

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

    context "empty arguments" do
      args = []
      it "should show agent help" do
        expect(LogStash::Agent).to receive(:help).once
        expect($stderr).to receive(:puts).once.with("No command given")
        expect($stderr).to receive(:puts).once
        expect(subject.run(args).wait).to eq(1)
      end
    end

    context "unknown command" do
      args = ["welp"]
      it "should show agent help" do
        expect(LogStash::Agent).to receive(:help).once
        expect($stderr).to receive(:puts).once.with("No such command \"welp\"")
        expect($stderr).to receive(:puts).once
        expect(subject.run(args).wait).to eq(1)
      end
    end
  end
end
