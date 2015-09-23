# encoding: utf-8
require "spec_helper"

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

  let(:count)    { 1 }
  let(:canceled) { true }

  let(:config) do
    <<-CONFIG
       input  {
          mock_generator {
            count => #{count}
            canceled => #{canceled}
          }
       }
       filter { noop {} }
    CONFIG
  end

  let(:events) do
    input(config) do |pipeline, queue|
      sleep 0.5
      events = []
      count.times do
        begin
          events << queue.pop(true)
        rescue
          # pass
        end
      end
      events
    end
  end

  context "compiled flush function" do

    context "when events are canceled during the proccess" do

      it "cancelled events should not propagate down the filters" do
        expect(events).to be_empty
      end

    end

    context "when events are not canceled during the proccess" do

      let(:canceled) { false }

      it "eents should not propagate down the filters" do
        expect(events).not_to be_empty
      end
    end
  end

end

  context "compiled filter funtions" do

    context "new events should propagate down the filters" do
      config <<-CONFIG
        filter {
          mock_clone {
            clones => ["mock_clone1", "mock_clone2"]
          }
          noop {
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
        expect(subject[1]["type"]).to eq("mock_clone1")
        expect(subject[1]["foo"]).to eq("bar")

        expect(subject[2]["message"]).to eq("hello")
        expect(subject[2]["type"]).to eq("mock_clone2")
        expect(subject[2]["foo"]).to eq("bar")
      end
    end

  end
end
