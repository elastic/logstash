require 'spec_helper'

require "logstash/runner"
require "logstash/agent"
require "logstash/kibana"
require "stud/task"


describe LogStash::Runner do

  context "argument parsing" do

    context "show help" do

      before(:each) do
        expect(subject).to receive(:show_help).once.and_return(nil)
      end

      it "run agent help" do
        args = ["agent", "-h"]
        expect(subject.run(args).wait).to eq(0)
      end

      it "run agent help and not run following commands" do
        args = ["agent", "-h", "web"]
        expect(subject.run(args).wait).to eq(0)
      end
    end

    context "with wrong arguments" do

      before(:each) do
        expect($stderr).to receive(:puts).once
      end

      it "show help with no arguments" do
        expect($stderr).to receive(:puts).once.and_return("No command given")
        expect(subject.run([]).wait).to eq(1)
      end

      it "show help for unknown commands" do
        expect($stderr).to receive(:puts).once.and_return("No such command welp")
        expect(subject.run(["welp"]).wait).to eq(1)
      end
    end



    context "with agent run" do

      before(:each) do
        expect(Stud::Task).to receive(:new).once.and_return(nil)
      end

      it "run agent" do
        args = ["agent", "-e", ""]
        expect(subject.run(args)).to be_nil
      end


      it "not run agent and web" do
        expect(LogStash::Kibana::Runner).to_not receive(:new)
        args = subject.run(["agent", "-e", "", "web"])
        expect(args).to be_nil
      end

    end
  end
end
