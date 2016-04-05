# encoding: utf-8
require "spec_helper"
require "logstash/runner"
require "stud/task"
require "stud/trap"

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

  describe "pipeline settings" do
    let(:pipeline_string) { "input { stdin {} } output { stdout {} }" }
    let(:base_pipeline_settings) { { :pipeline_id => "base", :debug_config => false } }
    let(:pipeline) { double("pipeline") }

    before(:each) do
      task = Stud::Task.new { 1 }
      allow(pipeline).to receive(:run).and_return(task)
    end

    context "when pipeline workers is not defined by the user" do
      it "should not pass the value to the pipeline" do
        expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, base_pipeline_settings).and_return(pipeline)
        args = ["agent", "-e", pipeline_string]
        subject.run(args).wait
      end
    end

    context "when pipeline workers is defined by the user" do
      it "should pass the value to the pipeline" do
        base_pipeline_settings[:pipeline_workers] = 2
        expect(LogStash::Pipeline).to receive(:new).with(pipeline_string, base_pipeline_settings).and_return(pipeline)
        args = ["agent", "-w", "2", "-e", pipeline_string]
        subject.run(args).wait
      end
    end
  end
end
