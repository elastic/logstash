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
    @events << event
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
        expect(pipeline.outputs.first.workers.size ).to eq(::LogStash::Pipeline::DEFAULT_OUTPUT_WORKERS)
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
    describe "flusher thread" do
      before(:each) do
        allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinput").and_return(DummyInput)
        allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
        allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
      end

      let(:config) { "input { dummyinput {} } output { dummyoutput {} }"}

      it "should start the flusher thread only after the pipeline is running" do
        pipeline = TestPipeline.new(config)

        expect(pipeline).to receive(:transition_to_running).ordered.and_call_original
        expect(pipeline).to receive(:start_flusher).ordered.and_call_original

        pipeline.run
      end
    end

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

  describe "max inflight warning" do
    let(:config) { "input { dummyinput {} } output { dummyoutput {} }" }
    let(:batch_size) { 1 }
    let(:pipeline) { LogStash::Pipeline.new(config, :pipeline_batch_size => batch_size, :pipeline_workers => 1) }
    let(:logger) { pipeline.logger }
    let(:warning_prefix) { /CAUTION: Recommended inflight events max exceeded!/ }

    before(:each) do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinput").and_return(DummyInput)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
      allow(logger).to receive(:warn)
      thread = Thread.new { pipeline.run }
      pipeline.shutdown
      thread.join
    end

    it "should not raise a max inflight warning if the max_inflight count isn't exceeded" do
      expect(logger).not_to have_received(:warn).with(warning_prefix)
    end

    context "with a too large inflight count" do
      let(:batch_size) { LogStash::Pipeline::MAX_INFLIGHT_WARN_THRESHOLD + 1 }

      it "should raise a max inflight warning if the max_inflight count is exceeded" do
        expect(logger).to have_received(:warn).with(warning_prefix)
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

  describe "stalling_threads" do
    before(:each) do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinput").and_return(DummyInput)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
    end

    context "when the pipeline doesn't have filters" do
      let(:pipeline_with_no_filters) do
        <<-eos
        input { dummyinput {} }
        output { dummyoutput {} }
        eos
      end

      it "doesn't raise an error" do
        pipeline = TestPipeline.new(pipeline_with_no_filters)
        pipeline.run
        expect { pipeline.stalling_threads_info }.to_not raise_error
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
      wait(5).for do
        next unless output && output.events && output.events.first
        output.events.first["message"].split("\n").count
      end.to eq(number_of_events)
      pipeline.shutdown
    end
  end

  context "Multiple pipelines" do
    before do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_return(LogStash::Inputs::Generator)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummyfilter").and_return(DummyFilter)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
    end

    let(:pipeline1) { LogStash::Pipeline.new("input { generator {} } filter { dummyfilter {} } output { dummyoutput {}}") }
    let(:pipeline2) { LogStash::Pipeline.new("input { generator {} } filter { dummyfilter {} } output { dummyoutput {}}") }

    it "should handle evaluating different config" do
      # When the functions are compiled from the AST it will generate instance
      # variables that are unique to the actual config, the intance are pointing
      # to conditionals/plugins.
      #
      # Before the `defined_singleton_method`, the definition of the method was
      # not unique per class, but the `instance variables` were unique per class.
      #
      # So the methods were trying to access instance variables that did not exist
      # in the current instance and was returning an array containing nil values for
      # the match.
      expect(pipeline1.output_func(LogStash::Event.new)).not_to include(nil)
      expect(pipeline1.filter_func(LogStash::Event.new)).not_to include(nil)
      expect(pipeline2.output_func(LogStash::Event.new)).not_to include(nil)
      expect(pipeline1.filter_func(LogStash::Event.new)).not_to include(nil)
    end
  end

  context "Pipeline object" do
    before do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_return(LogStash::Inputs::Generator)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummyfilter").and_return(DummyFilter)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)
    end

    let(:pipeline1) { LogStash::Pipeline.new("input { generator {} } filter { dummyfilter {} } output { dummyoutput {}}") }
    let(:pipeline2) { LogStash::Pipeline.new("input { generator {} } filter { dummyfilter {} } output { dummyoutput {}}") }

    it "should not add ivars" do
       expect(pipeline1.instance_variables).to eq(pipeline2.instance_variables)
    end
  end
end
