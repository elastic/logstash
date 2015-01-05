require "spec_helper"

describe LogStash::Pipeline do

  before(:each) do
    allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinput").and_return(DummyInput)
    allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
    allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
  end

  let(:test_config_without_output_workers) {
    <<-eos
    input {
      dummyinput {}
    }

    output {
      dummyoutput {}
    }
    eos
  }

  let(:test_config_with_output_workers) {
    <<-eos
    input {
      dummyinput {}
    }

    output {
      dummyoutput {
        workers => 2
      }
    }
    eos
  }

  context "output teardown" do

    context "without output-workers" do
      let(:pipeline) { TestPipeline.new(test_config_without_output_workers) }

      before(:each) do
        pipeline.run
      end

      it "have one output" do
        expect(pipeline.outputs.size).to eq(1)
      end

      it "have one worker plugins" do
        worker_plugins = pipeline.outputs.first.worker_plugins
        expect(worker_plugins.size).to eq(1)
      end

      it "have one teardown" do
        worker_plugins = pipeline.outputs.first.worker_plugins
        expect(worker_plugins.first.num_teardowns).to eq(1)
      end

    end

    context "with output-workers" do

      let(:pipeline) { TestPipeline.new(test_config_with_output_workers) }

      before(:each) do
        pipeline.run
      end

      it "have one output" do
        expect(pipeline.outputs.size).to eq(1)
      end

      it "have one teardown" do
        outputs = pipeline.outputs.first
        expect(outputs.num_teardowns).to eq(0)
      end

    end

  end
end
