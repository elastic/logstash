require "spec_helper"

class DummyInput < LogStash::Inputs::Base
  config_name "dummyinput"
  milestone 2

  def register
  end

  def run(queue)
  end

  def teardown
  end
end

class DummyFilter < LogStash::Filters::Base
  config_name "dummyfilter"
  milestone 2

  def register
  end

  def filter(event)
  end

  def teardown
  end
end

class DummyCodec < LogStash::Codecs::Base
  config_name "dummycodec"
  milestone 2

  def decode(data) 
    data
  end

  def encode(event) 
    event
  end

  def teardown
  end
end

class DummyOutput < LogStash::Outputs::Base
  config_name "dummyoutput"
  milestone 2
  
  attr_reader :num_teardowns

  def initialize(params={})
    super
    @num_teardowns = 0
  end

  def register
  end

  def receive(event)
  end

  def teardown
    @num_teardowns += 1
  end
end

class TestPipeline < LogStash::Pipeline
  attr_reader :outputs
  attr_reader :inputs
  attr_reader :filters
end

describe LogStash::Pipeline do

  before(:each) do
    LogStash::Plugin.stub(:lookup)
      .with("input", "dummyinput").and_return(DummyInput)
    LogStash::Plugin.stub(:lookup)
      .with("codec", "plain").and_return(DummyCodec)
    LogStash::Plugin.stub(:lookup)
      .with("output", "dummyoutput").and_return(DummyOutput)
    LogStash::Plugin.stub(:lookup)
      .with("filter", "dummyfilter").and_return(DummyFilter)
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
    it "should call teardown of output without output-workers" do
      pipeline = TestPipeline.new(test_config_without_output_workers)
      pipeline.run

      expect(pipeline.outputs.size ).to eq(1)
      expect(pipeline.outputs.first.worker_plugins.size ).to eq(1)
      expect(pipeline.outputs.first.worker_plugins.first.num_teardowns ).to eq(1)
    end

    it "should call output teardown correctly with output workers" do
      pipeline = TestPipeline.new(test_config_with_output_workers)
      pipeline.run

      expect(pipeline.outputs.size ).to eq(1)
      expect(pipeline.outputs.first.num_teardowns).to eq(0)
      pipeline.outputs.first.worker_plugins.each do |plugin|
        expect(plugin.num_teardowns ).to eq(1)
      end
    end
  end

  context "when plugins raise exceptions" do

    let(:dummy_config) {
      <<-eos
      input { dummyinput {} }
      filter { dummyfilter {} }
      output { dummyoutput {} }
      eos
    }

    let(:bad_event) { LogStash::Event.new("message" => "bad message") }
    let(:good_event) { LogStash::Event.new("message" => "good message") }
    let(:pipeline) { TestPipeline.new(dummy_config) }
    let(:input) { pipeline.inputs.first }
    let(:output) { pipeline.outputs.first }
    let(:filter) { pipeline.filters.first }

    context "transient exceptions" do
      context "input" do
        it "should restart and generate more events" do
          expect(input).to receive(:run).and_return do |queue|
            raise StandardError
          end
          expect(input).to receive(:run).and_return do |queue|
            queue << good_event
          end
          expect(output).to receive(:receive).once.with(good_event)
          expect(input).to receive(:teardown).once
          expect { pipeline.run }.to_not raise_error
        end
      end

      context "filter" do
        it "should restart and process the next event" do
          expect(input).to receive(:run).and_return do |queue|
            queue << bad_event
            queue << good_event
          end
          expect(filter).to receive(:filter).with(bad_event).and_return do |event|
            raise StandardError
          end
          expect(filter).to receive(:filter).with(good_event)
          expect(output).to receive(:receive).once.with(good_event)
          expect { pipeline.run }.to_not raise_error
        end
      end

      context "output" do
        it "should restart and process the next message" do
          expect(input).to receive(:run).and_return do |queue|
            queue << bad_event
            queue << good_event
          end
          expect(output).to receive(:receive).with(bad_event).and_return do |event|
            raise StandardError
          end
          expect(output).to receive(:receive).with(good_event).and_return do |event|
            # ...
          end
          expect(output).to receive(:teardown).once
          expect { pipeline.run }.to_not raise_error
        end
      end
    end

    context "fatal exceptions" do
      context "input" do
        it "should raise exception" do
          expect(input).to receive(:run).and_return do |queue|
            raise Exception
          end
          expect(filter).to_not receive(:filter)
          expect(pipeline).to receive(:shutdown)
          expect { pipeline.run }.to_not raise_error
        end
      end

      context "filter" do
        it "should raise exception" do
          expect(input).to receive(:run).and_return do |queue|
            queue << bad_event
          end
          expect(filter).to receive(:filter).with(bad_event).and_return do |event|
            raise Exception
          end
          expect(output).to_not receive(:receive)
          expect(pipeline).to receive(:shutdown)
          expect { pipeline.run }.to_not raise_error
        end
      end

      context "output" do
        it "should raise exception" do
          expect(input).to receive(:run).and_return do |queue|
            queue << bad_event
          end
          expect(output).to receive(:receive).with(bad_event).and_return do |event|
            raise Exception
          end
          expect(pipeline).to receive(:shutdown)
          expect { pipeline.run }.to_not raise_error
        end
      end
    end
  end
end
