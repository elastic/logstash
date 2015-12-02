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

class DummyInputGenerator < LogStash::Inputs::Base
  config_name "dummyinputgenerator"
  milestone 2

  def register
  end

  def run(queue)
    queue << Logstash::Event.new while !stop?
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
  
  def threadsafe?
    false
  end

  def receive(event)
  end

  def close
    @num_closes += 1
  end
end

class DummyOutputMore < DummyOutput
  config_name "dummyoutputmore"
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
  let(:worker_thread_count)     { 8 }
  let(:safe_thread_count)       { 1 }
  let(:override_thread_count)   { 42 }

  describe "defaulting the pipeline workers based on thread safety" do
    before(:each) do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinput").and_return(DummyInput)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummyfilter").and_return(DummyFilter)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummysafefilter").and_return(DummySafeFilter)
      allow(LogStash::Config::CpuCoreStrategy).to receive(:fifty_percent).and_return(worker_thread_count)
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
        expect(pipeline.outputs.first.worker_plugins.size ).to eq(1)
        expect(pipeline.outputs.first.worker_plugins.first.num_closes ).to eq(1)
      end

      it "should call output close correctly with output workers" do
        pipeline = TestPipeline.new(test_config_with_output_workers)
        pipeline.run

        expect(pipeline.outputs.size ).to eq(1)
        # We even close the parent output worker, even though it doesn't receive messages
        expect(pipeline.outputs.first.num_closes).to eq(1)
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

  context "metrics" do
    config <<-CONFIG
    input { }
    filter { }
    output { }
    CONFIG

    it "uses a `NullMetric` object if no metric is given" do
      pipeline = LogStash::Pipeline.new(config)
      expect(pipeline.metric).to be_kind_of(LogStash::Instrument::NullMetric)
    end
  end

  context "Multiples pipelines" do
    before do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinputgenerator").and_return(DummyInputGenerator)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummyfilter").and_return(DummyFilter)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutputmore").and_return(DummyOutputMore)
    end

    let(:pipeline1) { LogStash::Pipeline.new("input { dummyinputgenerator {} } filter { dummyfilter {} } output { dummyoutput {}}") }
    let(:pipeline2) { LogStash::Pipeline.new("input { dummyinputgenerator {} } filter { dummyfilter {} } output { dummyoutputmore {}}") }

    it "should handle evaluating different config" do
      expect(pipeline1.output_func(LogStash::Event.new)).not_to include(nil)
      expect(pipeline1.filter_func(LogStash::Event.new)).not_to include(nil)
      expect(pipeline2.output_func(LogStash::Event.new)).not_to include(nil)
      expect(pipeline1.filter_func(LogStash::Event.new)).not_to include(nil)
    end
  end
end
