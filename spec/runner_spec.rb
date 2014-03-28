require "logstash/runner"
require "logstash/agent"
require "logstash/kibana"
require "stud/task"

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
      expect(subject.run(args)).to eq([])
    end

    it "should run agent help and not run following commands" do
      expect(subject).to receive(:show_help).once.and_return(nil)
      args = ["agent", "-h", "web"]
      expect(subject.run(args)).to eq([])
    end

    it "should run agent and web" do
      expect(Stud::Task).to receive(:new).once
      args = ["agent", "-e", "", "web"]
      args = subject.run(args)
      expect(args).to eq(["web"])

      expect(LogStash::Kibana::Runner).to receive(:new).once.and_return(NullRunner.new)
      args = subject.run(args)
      expect(args).to eq(nil)
    end
  end
end
