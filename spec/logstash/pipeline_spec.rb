# encoding: utf-8
require "spec_helper"
require "logstash/inputs/generator"
require "logstash/filters/multiline"
require_relative "../support/mocks_classes"

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
  attr_reader :outputs, :settings
end

describe LogStash::Pipeline do
  let(:worker_thread_count)     { 5 }
  let(:safe_thread_count)       { 1 }
  let(:override_thread_count)   { 42 }
  let(:pipeline_settings_obj) { LogStash::SETTINGS }
  let(:pipeline_settings) { {} }

  before :each do
    pipeline_workers_setting = LogStash::SETTINGS.get_setting("pipeline.workers")
    allow(pipeline_workers_setting).to receive(:default).and_return(worker_thread_count)
    pipeline_settings.each {|k, v| pipeline_settings_obj.set(k, v) }
  end

  after :each do
    pipeline_settings_obj.reset
  end


  describe "event cancellation" do
    # test harness for https://github.com/elastic/logstash/issues/6055

    let(:output) { LogStash::Outputs::DummyOutputWithEventsArray.new }

    before do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_return(LogStash::Inputs::Generator)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutputwitheventsarray").and_return(LogStash::Outputs::DummyOutputWithEventsArray)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "drop").and_call_original
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "mutate").and_call_original
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_call_original
      allow(LogStash::Outputs::DummyOutputWithEventsArray).to receive(:new).with(any_args).and_return(output)
    end

    let(:config) do
      <<-CONFIG
        input {
          generator {
            lines => ["1", "2", "END"]
            count => 1
          }
        }
        filter {
          if [message] == "1" {
            drop {}
          }
          mutate { add_tag => ["notdropped"] }
        }
        output { dummyoutputwitheventsarray {} }
      CONFIG
    end

    it "should not propage cancelled events from filter to output" do
      abort_on_exception_state = Thread.abort_on_exception
      Thread.abort_on_exception = true

      pipeline = LogStash::Pipeline.new(config, pipeline_settings_obj)
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?
      wait(3).for do
        # give us a bit of time to flush the events
        # puts("*****" + output.events.map{|e| e.message}.to_s)
        output.events.map{|e| e.get("message")}.include?("END")
      end.to be_truthy
      expect(output.events.size).to eq(2)
      expect(output.events[0].get("tags")).to eq(["notdropped"])
      expect(output.events[1].get("tags")).to eq(["notdropped"])
      pipeline.shutdown

      Thread.abort_on_exception = abort_on_exception_state
    end
  end

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

      describe "debug compiled" do
        let(:logger) { double("pipeline logger").as_null_object }

        before do
          expect(TestPipeline).to receive(:logger).and_return(logger)
          allow(logger).to receive(:debug?).and_return(true)
        end

        it "should not receive a debug message with the compiled code" do
          pipeline_settings_obj.set("config.debug", false)
          expect(logger).not_to receive(:debug).with(/Compiled pipeline/, anything)
          pipeline = TestPipeline.new(test_config_with_filters)
        end

        it "should print the compiled code if config.debug is set to true" do
          pipeline_settings_obj.set("config.debug", true)
          expect(logger).to receive(:debug).with(/Compiled pipeline/, anything)
          pipeline = TestPipeline.new(test_config_with_filters, pipeline_settings_obj)
        end
      end

      context "when there is no command line -w N set" do
        it "starts one filter thread" do
          msg = "Defaulting pipeline worker threads to 1 because there are some filters that might not work with multiple worker threads"
          pipeline = TestPipeline.new(test_config_with_filters)
          expect(pipeline.logger).to receive(:warn).with(msg,
            {:count_was=>worker_thread_count, :filters=>["dummyfilter"]})
          pipeline.run
          expect(pipeline.worker_threads.size).to eq(safe_thread_count)
          pipeline.shutdown
        end
      end

      context "when there is command line -w N set" do
        let(:pipeline_settings) { {"pipeline.workers" => override_thread_count } }
        it "starts multiple filter thread" do
          msg = "Warning: Manual override - there are filters that might" +
                " not work with multiple worker threads"
          pipeline = TestPipeline.new(test_config_with_filters, pipeline_settings_obj)
          expect(pipeline.logger).to receive(:warn).with(msg,
            {:worker_threads=> override_thread_count, :filters=>["dummyfilter"]})
          pipeline.run
          expect(pipeline.worker_threads.size).to eq(override_thread_count)
          pipeline.shutdown
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
        pipeline.shutdown
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
      let(:pipeline) { TestPipeline.new(test_config_without_output_workers) }
      let(:output) { pipeline.outputs.first }

      before do
        allow(output).to receive(:do_close)
      end

      after do
        pipeline.shutdown
      end
      
      it "should call close of output without output-workers" do
        pipeline.run

        expect(output).to have_received(:do_close).once
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
        pipeline.shutdown
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
        expect(subject.get("message")).to eq("hello")
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

        expect(subject[0].get("message")).to eq("foo\nbar")
        expect(subject[0].get("type")).to be_nil
        expect(subject[1].get("message")).to eq("foo\nbar")
        expect(subject[1].get("type")).to eq("clone1")
      end
    end
  end

  describe "max inflight warning" do
    let(:config) { "input { dummyinput {} } output { dummyoutput {} }" }
    let(:batch_size) { 1 }
    let(:pipeline_settings) { { "pipeline.batch.size" => batch_size, "pipeline.workers" => 1 } }
    let(:pipeline) { LogStash::Pipeline.new(config, pipeline_settings_obj) }
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

        expect(subject[0].get("message")).to eq("hello")
        expect(subject[0].get("type")).to be_nil
        expect(subject[0].get("foo")).to eq("bar")

        expect(subject[1].get("message")).to eq("hello")
        expect(subject[1].get("type")).to eq("clone1")
        expect(subject[1].get("foo")).to eq("bar")

        expect(subject[2].get("message")).to eq("hello")
        expect(subject[2].get("type")).to eq("clone2")
        expect(subject[2].get("foo")).to eq("bar")
      end
    end
  end

  context "metrics" do
    config <<-CONFIG
    input { }
    filter { }
    output { }
    CONFIG

    it "uses a `NullMetric` object if `metric.collect` is set to false" do
      settings = double("LogStash::SETTINGS")

      allow(settings).to receive(:get_value).with("pipeline.id").and_return("main")
      allow(settings).to receive(:get_value).with("metric.collect").and_return(false)
      allow(settings).to receive(:get_value).with("config.debug").and_return(false)
      allow(settings).to receive(:get).with("queue.type").and_return("memory")
      allow(settings).to receive(:get).with("queue.page_capacity").and_return(1024 * 1024)
      allow(settings).to receive(:get).with("queue.max_events").and_return(250)
      allow(settings).to receive(:get).with("queue.max_bytes").and_return(1024 * 1024 * 1024)
      allow(settings).to receive(:get).with("queue.checkpoint.acks").and_return(1024)
      allow(settings).to receive(:get).with("queue.checkpoint.writes").and_return(1024)
      allow(settings).to receive(:get).with("queue.checkpoint.interval").and_return(1000)

      pipeline = LogStash::Pipeline.new(config, settings)
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
      pipeline = LogStash::Pipeline.new(config, pipeline_settings_obj)
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?
      wait(3).for do
        # give us a bit of time to flush the events
        output.events.empty?
      end.to be_falsey
      event = output.events.pop
      expect(event.get("message").count("\n")).to eq(99)
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
      # variables that are unique to the actual config, the intances are pointing
      # to conditionals and/or plugins.
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

  context "#started_at" do
    # use a run limiting count to shutdown the pipeline automatically
    let(:config) do
      <<-EOS
      input {
        generator { count => 10 }
      }
      EOS
    end

    subject { described_class.new(config) }

    it "returns nil when the pipeline isnt started" do
      expect(subject.started_at).to be_nil
    end

    it "return when the pipeline started working" do
      subject.run
      expect(subject.started_at).to be < Time.now
      subject.shutdown
    end
  end

  context "#uptime" do
    let(:config) do
      <<-EOS
      input {
        generator {}
      }
      EOS
    end
    subject { described_class.new(config) }

    context "when the pipeline is not started" do
      it "returns 0" do
        expect(subject.uptime).to eq(0)
      end
    end

    context "when the pipeline is started" do
      it "return the duration in milliseconds" do
        t = Thread.new { subject.run }
        sleep(0.1)
        expect(subject.uptime).to be > 0
        subject.shutdown
      end
    end
  end

  context "when collecting metrics in the pipeline" do
    let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new) }

    subject { described_class.new(config, pipeline_settings_obj, metric) }

    let(:pipeline_settings) { { "pipeline.id" => pipeline_id } }
    let(:pipeline_id) { "main" }
    let(:number_of_events) { 420 }
    let(:multiline_id) { "my-multiline" }
    let(:multiline_id_other) { "my-multiline_other" }
    let(:dummy_output_id) { "my-dummyoutput" }
    let(:generator_id) { "my-generator" }
    let(:config) do
      <<-EOS
      input {
        generator {
           count => #{number_of_events}
           id => "#{generator_id}"
        }
      }
      filter {
         multiline {
              id => "#{multiline_id}"
              pattern => "hello"
              what => next
          }
          multiline {
               id => "#{multiline_id_other}"
               pattern => "hello"
               what => next
           }
      }
      output {
        dummyoutput {
          id => "#{dummy_output_id}"
        }
      }
      EOS
    end
    let(:dummyoutput) { DummyOutput.new({ "id" => dummy_output_id }) }
    let(:metric_store) { subject.metric.collector.snapshot_metric.metric_store }

    before :each do
      allow(DummyOutput).to receive(:new).with(any_args).and_return(dummyoutput)
      allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_return(LogStash::Inputs::Generator)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(LogStash::Codecs::Plain)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "multiline").and_return(LogStash::Filters::Multiline)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(DummyOutput)

      Thread.new { subject.run }
      # make sure we have received all the generated events
      wait(3).for do
        # give us a bit of time to flush the events
        dummyoutput.events.size < number_of_events
      end.to be_falsey
    end

    after :each do
      subject.shutdown
    end

    context "global metric" do
      let(:collected_metric) { metric_store.get_with_path("stats/events") }

      it "populates the different metrics" do
        expect(collected_metric[:stats][:events][:duration_in_millis].value).not_to be_nil
        expect(collected_metric[:stats][:events][:in].value).to eq(number_of_events)
        expect(collected_metric[:stats][:events][:filtered].value).to eq(number_of_events)
        expect(collected_metric[:stats][:events][:out].value).to eq(number_of_events)
      end
    end

    context "pipelines" do
      let(:collected_metric) { metric_store.get_with_path("stats/pipelines/") }

      it "populates the pipelines core metrics" do
        expect(collected_metric[:stats][:pipelines][:main][:events][:duration_in_millis].value).not_to be_nil
        expect(collected_metric[:stats][:pipelines][:main][:events][:in].value).to eq(number_of_events)
        expect(collected_metric[:stats][:pipelines][:main][:events][:filtered].value).to eq(number_of_events)
        expect(collected_metric[:stats][:pipelines][:main][:events][:out].value).to eq(number_of_events)
      end

      it "populates the filter metrics" do
        [multiline_id, multiline_id_other].map(&:to_sym).each do |id|
          [:in, :out].each do |metric_key|
            plugin_name = id.to_sym
            expect(collected_metric[:stats][:pipelines][:main][:plugins][:filters][plugin_name][:events][metric_key].value).to eq(number_of_events)
          end
        end
      end

      it "populates the output metrics" do
        plugin_name = dummy_output_id.to_sym
        expect(collected_metric[:stats][:pipelines][:main][:plugins][:outputs][plugin_name][:events][:out].value).to eq(number_of_events)
      end

      it "populates the name of the output plugin" do
        plugin_name = dummy_output_id.to_sym
        expect(collected_metric[:stats][:pipelines][:main][:plugins][:outputs][plugin_name][:name].value).to eq(DummyOutput.config_name)
      end

      it "populates the name of the filter plugin" do
        [multiline_id, multiline_id_other].map(&:to_sym).each do |id|
          plugin_name = id.to_sym
          expect(collected_metric[:stats][:pipelines][:main][:plugins][:filters][plugin_name][:name].value).to eq(LogStash::Filters::Multiline.config_name)
        end
      end
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
