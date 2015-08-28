# encoding: utf-8
require "spec_helper"

class DummyInput < LogStash::Inputs::Base
  config_name "dummyinput"
  milestone 2

  def register
  end

  def run(queue)
  end

  def close
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

  def close
  end
end

class DummyOutput < LogStash::Outputs::Base
  config_name "dummyoutput"
  milestone 2

  attr_reader :num_closes

  def initialize(params={})
    super
    @num_closes = 0
  end

  def register
  end

  def receive(event)
  end

  def close
    @num_closes += 1
  end
end

class TestPipeline < LogStash::Pipeline
  attr_reader :outputs
end

describe LogStash::Pipeline do

context "close" do

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

    context "output close" do
      it "should call close of output without output-workers" do
        pipeline = TestPipeline.new(test_config_without_output_workers)
        pipeline.run

        expect(pipeline.outputs.size ).to eq(1)
        expect(pipeline.outputs.first.worker_plugins.size ).to eq(1)
        expect(pipeline.outputs.first.worker_plugins.first.num_closes ).to eq(1)
      end

      it "should call output close correctly with output workers" do
        pipeline = TestPipeline.new(test_config_with_output_workers)
        pipeline.run

        expect(pipeline.outputs.size ).to eq(1)
        expect(pipeline.outputs.first.num_closes).to eq(0)
        pipeline.outputs.first.worker_plugins.each do |plugin|
          expect(plugin.num_closes ).to eq(1)
        end
      end
    end
  end

  context "compiled flush function" do

    context "cancelled events should not propagate down the filters" do
      config <<-CONFIG
        filter {
          multiline {
           pattern => "hello"
           what => next
          }
          multiline {
           pattern => "hello"
           what => next
          }
        }
      CONFIG

      sample("hello") do
        expect(subject["message"]).to eq("hello")
      end
    end

    context "new events should propagate down the filters" do
      config <<-CONFIG
        filter {
          clone {
            clones => ["clone1"]
          }
          multiline {
            pattern => "bar"
            what => previous
          }
        }
      CONFIG

      sample(["foo", "bar"]) do
        expect(subject.size).to eq(2)

        expect(subject[0]["message"]).to eq("foo\nbar")
        expect(subject[0]["type"]).to be_nil
        expect(subject[1]["message"]).to eq("foo\nbar")
        expect(subject[1]["type"]).to eq("clone1")
      end
    end
  end

  context "compiled filter funtions" do

    context "new events should propagate down the filters" do
      config <<-CONFIG
        filter {
          clone {
            clones => ["clone1", "clone2"]
          }
          mutate {
            add_field => {"foo" => "bar"}
          }
        }
      CONFIG

      sample("hello") do
        expect(subject.size).to eq(3)

        expect(subject[0]["message"]).to eq("hello")
        expect(subject[0]["type"]).to be_nil
        expect(subject[0]["foo"]).to eq("bar")

        expect(subject[1]["message"]).to eq("hello")
        expect(subject[1]["type"]).to eq("clone1")
        expect(subject[1]["foo"]).to eq("bar")

        expect(subject[2]["message"]).to eq("hello")
        expect(subject[2]["type"]).to eq("clone2")
        expect(subject[2]["foo"]).to eq("bar")
      end
    end

  end
end
