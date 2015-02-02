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
    let(:pipeline) { LogStash::Pipeline.new(dummy_config) }

    context "transient exceptions" do
      context "input" do
        it "should restart and generate more events" do
          expect_any_instance_of(DummyInput).to receive(:run).and_return do |queue|
            raise StandardError
          end
          expect_any_instance_of(DummyInput).to receive(:run).and_return do |queue|
            queue << good_event
          end
          expect_any_instance_of(DummyOutput).to receive(:receive).once.with(good_event)
          expect_any_instance_of(DummyInput).to receive(:teardown).once
          expect { pipeline.run }.to_not raise_error
        end
      end

      context "filter" do
        it "should restart and process the next event" do
          expect_any_instance_of(DummyInput).to receive(:run).and_return do |queue|
            queue << bad_event
            queue << good_event
          end
          expect_any_instance_of(DummyFilter).to receive(:filter).with(bad_event).and_return do |event|
            raise StandardError
          end
          expect_any_instance_of(DummyFilter).to receive(:filter).with(good_event)
          expect_any_instance_of(DummyOutput).to receive(:receive).once.with(good_event)
          expect_any_instance_of(DummyFilter).to receive(:teardown).once
          expect { pipeline.run }.to_not raise_error
        end
      end

      context "output" do
        it "should restart and process the next message" do
          expect_any_instance_of(DummyInput).to receive(:run).and_return do |queue|
            queue << bad_event
            queue << good_event
          end
          expect_any_instance_of(DummyOutput).to receive(:receive).with(bad_event).and_return do |event|
            raise StandardError
          end
          expect_any_instance_of(DummyOutput).to receive(:receive).with(good_event).and_return do |event|
            # ...
          end
          expect_any_instance_of(DummyOutput).to receive(:teardown).once
          expect { pipeline.run }.to_not raise_error
        end
      end
    end

    context "fatal exceptions" do
      context "input" do
        it "should raise exception" do
          expect_any_instance_of(DummyInput).to receive(:run).and_return do |queue|
            raise Exception
          end
          expect_any_instance_of(DummyFilter).to_not receive(:filter)
          expect { pipeline.run }.to raise_error(Exception)
        end
      end

      context "filter" do
        it "should raise exception" do
          expect_any_instance_of(DummyInput).to receive(:run).and_return do |queue|
            queue << bad_event
          end
          expect_any_instance_of(DummyFilter).to receive(:filter).with(bad_event).and_return do |event|
            raise Exception
          end
          expect_any_instance_of(DummyOutput).to_not receive(:receive)
          expect { pipeline.run }.to raise_error(Exception)
        end
      end

      context "output" do
        it "should raise exception" do
          expect_any_instance_of(DummyInput).to receive(:run).and_return do |queue|
            queue << bad_event
          end
          expect_any_instance_of(DummyOutput).to receive(:receive).with(bad_event).and_return do |event|
            raise Exception
          end
          expect { pipeline.run }.to raise_error(Exception)
        end
      end
    end
  end
end
