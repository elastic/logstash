# encoding: utf-8
require "spec_helper"
require "logstash/inputs/generator"
require "logstash/filters/multiline"

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

  attr_reader :num_closes, :events

  def initialize(params={})
    super
    @num_closes = 0
    @events = []
  end

  def register
  end

  def receive(event)
    @events << events
  end

  def close
    @num_closes += 1
  end
end

class DummyFilter < LogStash::Filters::Base
  config_name "dummyfilter"
  milestone 2

  def register() end

  def filter(event) end

  def threadsafe?() false; end

  def close() end
end

class DummySafeFilter < LogStash::Filters::Base
  config_name "dummysafefilter"
  milestone 2

  def register() end

  def filter(event) end

  def threadsafe?() true; end

  def close() end
end

class TestPipeline < LogStash::Pipeline
  attr_reader :outputs, :settings, :logger
end

describe LogStash::Pipeline do
  let(:worker_thread_count)     { LogStash::Pipeline::DEFAULT_SETTINGS[:default_pipeline_workers] }
  let(:safe_thread_count)       { 1 }
  let(:override_thread_count)   { 42 }

  describe "defaulting the pipeline workers based on thread safety" do
    before(:each) do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinput").and_return(DummyInput)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummyfilter").and_return(DummyFilter)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummysafefilter").and_return(DummySafeFilter)
    end

    context "when there are some not threadsafe filters" do
      let(:test_config_with_filters) {
        <<-eos
        input {
          dummyinput {}
        }

        filter {
          dummyfilter {}
        }

        output {
          dummyoutput {}
        }
        eos
      }

      context "when there is no command line -w N set" do
        it "starts one filter thread" do
          msg = "Defaulting pipeline worker threads to 1 because there are some" +
                " filters that might not work with multiple worker threads"
          pipeline = TestPipeline.new(test_config_with_filters)
          expect(pipeline.logger).to receive(:warn).with(msg,
            {:count_was=>worker_thread_count, :filters=>["dummyfilter"]})
          pipeline.run
          expect(pipeline.worker_threads.size).to eq(safe_thread_count)
        end
      end

      context "when there is command line -w N set" do
        it "starts multiple filter thread" do
          msg = "Warning: Manual override - there are filters that might" +
                " not work with multiple worker threads"
          pipeline = TestPipeline.new(test_config_with_filters)
          expect(pipeline.logger).to receive(:warn).with(msg,
            {:worker_threads=> override_thread_count, :filters=>["dummyfilter"]})
          pipeline.configure(:pipeline_workers, override_thread_count)
          pipeline.run
          expect(pipeline.worker_threads.size).to eq(override_thread_count)
        end
      end
    end

    context "when there are threadsafe filters only" do
      let(:test_config_with_filters) {
        <<-eos
        input {
          dummyinput {}
        }

        filter {
          dummysafefilter {}
        }

        output {
          dummyoutput {}
        }
        eos
      }

      it "starts multiple filter threads" do
        pipeline = TestPipeline.new(test_config_with_filters)
        pipeline.run
        expect(pipeline.worker_threads.size).to eq(worker_thread_count)
      end
    end
  end

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
        expect(pipeline.outputs.first.workers.size ).to eq(1)
        expect(pipeline.outputs.first.workers.first.num_closes ).to eq(1)
      end

      it "should call output close correctly with output workers" do
        pipeline = TestPipeline.new(test_config_with_output_workers)
        pipeline.run

        expect(pipeline.outputs.size ).to eq(1)
        # We even close the parent output worker, even though it doesn't receive messages

        output_delegator = pipeline.outputs.first
        output = output_delegator.workers.first

        expect(output.num_closes).to eq(1)
        output_delegator.workers.each do |plugin|
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

  context "Periodic Flush" do
    let(:number_of_events) { 100 }
    let(:config) do
      <<-EOS
      input {
        generator {
          count => #{number_of_events}
        }
      }
      filter {
        multiline { 
          pattern => "^NeverMatch"
          negate => true
          what => "previous"
        }
      }
      output {
        dummyoutput {}
      }
      EOS
    end
    let(:output) { DummyOutput.new }
    
    before do
      allow(DummyOutput).to receive(:new).with(any_args).and_return(output)
      allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_return(LogStash::Inputs::Generator)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(LogStash::Codecs::Plain)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "multiline").and_return(LogStash::Filters::Multiline)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
    end

    it "flushes the buffered contents of the filter" do
      Thread.abort_on_exception = true
      pipeline = LogStash::Pipeline.new(config, { :flush_interval => 1 })
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?
      # give us a bit of time to flush the events
      wait(5).for { output.events.size }.to eq(number_of_events)
      pipeline.shutdown
    end
  end
end
