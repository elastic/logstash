# encoding: utf-8
require "spec_helper"
require "logstash/inputs/generator"
require "logstash/filters/multiline"
require_relative "../support/mocks_classes"
require_relative "../support/helpers"
require_relative "../logstash/pipeline_reporter_spec" # for DummyOutput class

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

class DummyOutputMore < ::LogStash::Outputs::DummyOutput
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

class DummyFlushingFilter < LogStash::Filters::Base
  config_name "dummyflushingfilter"
  milestone 2

  def register() end
  def filter(event) end
  def periodic_flush
    true
  end
  def flush(options)
    return [::LogStash::Event.new("message" => "dummy_flush")]
  end
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

    it "should not propagate cancelled events from filter to output" do
      abort_on_exception_state = Thread.abort_on_exception
      Thread.abort_on_exception = true

      pipeline = mock_pipeline_from_string(config, pipeline_settings_obj)
      t = Thread.new { pipeline.run }
      sleep(0.1) until pipeline.ready?
      wait(3).for do
        # give us a bit of time to flush the events
        # puts("*****" + output.events.map{|e| e.message}.to_s)
        output.events.map{|e| e.get("message")}.include?("END")
      end.to be_truthy
      expect(output.events.size).to eq(2)
      expect(output.events[0].get("tags")).to eq(["notdropped"])
      expect(output.events[1].get("tags")).to eq(["notdropped"])
      pipeline.shutdown
      t.join

      Thread.abort_on_exception = abort_on_exception_state
    end
  end

  describe "defaulting the pipeline workers based on thread safety" do
    before(:each) do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinput").and_return(DummyInput)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)
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
          expect(::LogStash::Pipeline).to receive(:logger).and_return(logger)
          allow(logger).to receive(:debug?).and_return(true)
        end

        it "should not receive a debug message with the compiled code" do
          pipeline_settings_obj.set("config.debug", false)
          expect(logger).not_to receive(:debug).with(/Compiled pipeline/, anything)
          pipeline = mock_pipeline_from_string(test_config_with_filters)
          pipeline.close
        end

        it "should print the compiled code if config.debug is set to true" do
          pipeline_settings_obj.set("config.debug", true)
          expect(logger).to receive(:debug).with(/Compiled pipeline/, anything)
          pipeline = mock_pipeline_from_string(test_config_with_filters, pipeline_settings_obj)
          pipeline.close
        end
      end

      context "when there is no command line -w N set" do
        it "starts one filter thread" do
          msg = "Defaulting pipeline worker threads to 1 because there are some filters that might not work with multiple worker threads"
          pipeline = mock_pipeline_from_string(test_config_with_filters)
          expect(pipeline.logger).to receive(:warn).with(msg,
            hash_including({:count_was=>worker_thread_count, :filters=>["dummyfilter"]}))
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
          pipeline = mock_pipeline_from_string(test_config_with_filters, pipeline_settings_obj)
          expect(pipeline.logger).to receive(:warn).with(msg, hash_including({:worker_threads=> override_thread_count, :filters=>["dummyfilter"]}))
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
        skip("This test has been failing periodically since November 2016. Tracked as https://github.com/elastic/logstash/issues/6245")
        pipeline = mock_pipeline_from_string(test_config_with_filters)
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
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)
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
      let(:pipeline) { mock_pipeline_from_string(test_config_without_output_workers) }
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
        allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)
      end

      let(:config) { "input { dummyinput {} } output { dummyoutput {} }"}

      it "should start the flusher thread only after the pipeline is running" do
        pipeline = mock_pipeline_from_string(config)

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
    let(:pipeline) { mock_pipeline_from_string(config, pipeline_settings_obj) }
    let(:logger) { pipeline.logger }
    let(:warning_prefix) { Regexp.new("CAUTION: Recommended inflight events max exceeded!") }

    before(:each) do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinput").and_return(DummyInput)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)
      allow(logger).to receive(:warn)

      # pipeline must be first called outside the thread context because it lazily initialize and will create a
      # race condition if called in the thread
      p = pipeline
      t = Thread.new { p.run }
      sleep(0.1) until pipeline.ready?
      pipeline.shutdown
      t.join
    end

    it "should not raise a max inflight warning if the max_inflight count isn't exceeded" do
      expect(logger).not_to have_received(:warn).with(warning_prefix)
    end

    context "with a too large inflight count" do
      let(:batch_size) { LogStash::Pipeline::MAX_INFLIGHT_WARN_THRESHOLD + 1 }

      it "should raise a max inflight warning if the max_inflight count is exceeded" do
        expect(logger).to have_received(:warn).with(warning_prefix, hash_including(:pipeline_id => anything))
      end
    end
  end

  context "compiled filter functions" do
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
    config = "input { } filter { } output { }"

    let(:settings) { LogStash::SETTINGS.clone }
    subject { mock_pipeline_from_string(config, settings, metric) }

    after :each do
      subject.close
    end

    context "when metric.collect is disabled" do
      before :each do
        settings.set("metric.collect", false)
      end

      context "if namespaced_metric is nil" do
        let(:metric) { nil }
        it "uses a `NullMetric` object" do
          expect(subject.metric).to be_a(LogStash::Instrument::NullMetric)
        end
      end

      context "if namespaced_metric is a Metric object" do
        let(:collector) { ::LogStash::Instrument::Collector.new }
        let(:metric) { ::LogStash::Instrument::Metric.new(collector) }

        it "uses a `NullMetric` object" do
          expect(subject.metric).to be_a(LogStash::Instrument::NullMetric)
        end

        it "uses the same collector" do
          expect(subject.metric.collector).to be(collector)
        end
      end

      context "if namespaced_metric is a NullMetric object" do
        let(:collector) { ::LogStash::Instrument::Collector.new }
        let(:metric) { ::LogStash::Instrument::NullMetric.new(collector) }

        it "uses a `NullMetric` object" do
          expect(subject.metric).to be_a(::LogStash::Instrument::NullMetric)
        end

        it "uses the same collector" do
          expect(subject.metric.collector).to be(collector)
        end
      end
    end

    context "when metric.collect is enabled" do
      before :each do
        settings.set("metric.collect", true)
      end

      context "if namespaced_metric is nil" do
        let(:metric) { nil }
        it "uses a `NullMetric` object" do
          expect(subject.metric).to be_a(LogStash::Instrument::NullMetric)
        end
      end

      context "if namespaced_metric is a Metric object" do
        let(:collector) { ::LogStash::Instrument::Collector.new }
        let(:metric) { ::LogStash::Instrument::Metric.new(collector) }

        it "uses a `Metric` object" do
          expect(subject.metric).to be_a(LogStash::Instrument::Metric)
        end

        it "uses the same collector" do
          expect(subject.metric.collector).to be(collector)
        end
      end

      context "if namespaced_metric is a NullMetric object" do
        let(:collector) { ::LogStash::Instrument::Collector.new }
        let(:metric) { ::LogStash::Instrument::NullMetric.new(collector) }

        it "uses a `NullMetric` object" do
          expect(subject.metric).to be_a(LogStash::Instrument::NullMetric)
        end

        it "uses the same collector" do
          expect(subject.metric.collector).to be(collector)
        end
      end
    end
  end

  context "Multiples pipelines" do
    before do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "dummyinputgenerator").and_return(DummyInputGenerator)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummyfilter").and_return(DummyFilter)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutputmore").and_return(DummyOutputMore)
    end

    # multiple pipelines cannot be instantiated using the same PQ settings, force memory queue
    before :each do
      pipeline_workers_setting = LogStash::SETTINGS.get_setting("queue.type")
      allow(pipeline_workers_setting).to receive(:value).and_return("memory")
      pipeline_settings.each {|k, v| pipeline_settings_obj.set(k, v) }
    end

    let(:pipeline1) { mock_pipeline_from_string("input { dummyinputgenerator {} } filter { dummyfilter {} } output { dummyoutput {}}") }
    let(:pipeline2) { mock_pipeline_from_string("input { dummyinputgenerator {} } filter { dummyfilter {} } output { dummyoutputmore {}}") }

    after  do
      pipeline1.close
      pipeline2.close
    end

    it "should handle evaluating different config" do
      expect(pipeline1.output_func(LogStash::Event.new)).not_to include(nil)
      expect(pipeline1.filter_func(LogStash::Event.new)).not_to include(nil)
      expect(pipeline2.output_func(LogStash::Event.new)).not_to include(nil)
      expect(pipeline1.filter_func(LogStash::Event.new)).not_to include(nil)
    end
  end

  context "Periodic Flush" do
    let(:config) do
      <<-EOS
      input {
        dummy_input {}
      }
      filter {
        dummy_flushing_filter {}
      }
      output {
        dummy_output {}
      }
      EOS
    end
    let(:output) { ::LogStash::Outputs::DummyOutput.new }

    before do
      allow(::LogStash::Outputs::DummyOutput).to receive(:new).with(any_args).and_return(output)
      allow(LogStash::Plugin).to receive(:lookup).with("input", "dummy_input").and_return(DummyInput)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummy_flushing_filter").and_return(DummyFlushingFilter)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummy_output").and_return(::LogStash::Outputs::DummyOutput)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(LogStash::Codecs::Plain)
    end

    it "flush periodically" do
      Thread.abort_on_exception = true
      pipeline = mock_pipeline_from_string(config, pipeline_settings_obj)
      t = Thread.new { pipeline.run }
      sleep(0.1) until pipeline.ready?
      wait(10).for do
        # give us a bit of time to flush the events
        output.events.empty?
      end.to be_falsey

      expect(output.events.any? {|e| e.get("message") == "dummy_flush"}).to eq(true)

      pipeline.shutdown

      t.join
    end
  end

  context "Multiple pipelines" do
    before do
      allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_return(LogStash::Inputs::Generator)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(DummyCodec)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "dummyfilter").and_return(DummyFilter)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)
    end

    let(:pipeline1) { mock_pipeline_from_string("input { generator {} } filter { dummyfilter {} } output { dummyoutput {}}") }
    let(:pipeline2) { mock_pipeline_from_string("input { generator {} } filter { dummyfilter {} } output { dummyoutput {}}") }

    # multiple pipelines cannot be instantiated using the same PQ settings, force memory queue
    before :each do
      pipeline_workers_setting = LogStash::SETTINGS.get_setting("queue.type")
      allow(pipeline_workers_setting).to receive(:value).and_return("memory")
      pipeline_settings.each {|k, v| pipeline_settings_obj.set(k, v) }
    end

    it "should handle evaluating different config" do
      # When the functions are compiled from the AST it will generate instance
      # variables that are unique to the actual config, the instances are pointing
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

    subject { mock_pipeline_from_string(config) }

    context "when the pipeline is not started" do
      after :each do
        subject.close
      end

      it "returns nil when the pipeline isnt started" do
        expect(subject.started_at).to be_nil
      end
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
    subject { mock_pipeline_from_string(config) }

    context "when the pipeline is not started" do
      after :each do
        subject.close
      end

      it "returns 0" do
        expect(subject.uptime).to eq(0)
      end
    end

    context "when the pipeline is started" do
      it "return the duration in milliseconds" do
        # subject must be first call outside the thread context because of lazy initialization
        s = subject
        t = Thread.new { s.run }
        sleep(0.1) until subject.ready?

        sleep(0.1)
        expect(subject.uptime).to be > 0
        subject.shutdown
        t.join
      end
    end
  end

  context "when collecting metrics in the pipeline" do
    let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new) }

    subject { mock_pipeline_from_string(config, pipeline_settings_obj, metric) }

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
    let(:dummyoutput) { ::LogStash::Outputs::DummyOutput.new({ "id" => dummy_output_id }) }
    let(:metric_store) { subject.metric.collector.snapshot_metric.metric_store }
    let(:pipeline_thread) do
      # subject has to be called for the first time outside the thread because it will create a race condition
      # with the subject.ready? call since subject is lazily initialized
      s = subject
      Thread.new { s.run }
    end

    before :each do
      allow(::LogStash::Outputs::DummyOutput).to receive(:new).with(any_args).and_return(dummyoutput)
      allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_return(LogStash::Inputs::Generator)
      allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_return(LogStash::Codecs::Plain)
      allow(LogStash::Plugin).to receive(:lookup).with("filter", "multiline").and_return(LogStash::Filters::Multiline)
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)

      pipeline_thread
      sleep(0.1) until subject.ready?

      # make sure we have received all the generated events
      wait(3).for do
        # give us a bit of time to flush the events
        dummyoutput.events.size >= number_of_events
      end.to be_truthy
    end

    after :each do
      subject.shutdown
      pipeline_thread.join
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

        expect(collected_metric[:stats][:pipelines][:main][:plugins][:outputs][plugin_name][:events][:in].value).to eq(number_of_events)
        expect(collected_metric[:stats][:pipelines][:main][:plugins][:outputs][plugin_name][:events][:out].value).to eq(number_of_events)
        expect(collected_metric[:stats][:pipelines][:main][:plugins][:outputs][plugin_name][:events][:duration_in_millis].value).not_to be_nil
      end

      it "populates the name of the output plugin" do
        plugin_name = dummy_output_id.to_sym
        expect(collected_metric[:stats][:pipelines][:main][:plugins][:outputs][plugin_name][:name].value).to eq(::LogStash::Outputs::DummyOutput.config_name)
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
      allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)
    end

    let(:pipeline1) { mock_pipeline_from_string("input { generator {} } filter { dummyfilter {} } output { dummyoutput {}}") }
    let(:pipeline2) { mock_pipeline_from_string("input { generator {} } filter { dummyfilter {} } output { dummyoutput {}}") }

    # multiple pipelines cannot be instantiated using the same PQ settings, force memory queue
    before :each do
      pipeline_workers_setting = LogStash::SETTINGS.get_setting("queue.type")
      allow(pipeline_workers_setting).to receive(:value).and_return("memory")
      pipeline_settings.each {|k, v| pipeline_settings_obj.set(k, v) }
    end

    it "should not add ivars" do
       expect(pipeline1.instance_variables).to eq(pipeline2.instance_variables)
    end
  end

  context "#system" do
    after do
      pipeline.close # close the queue
    end

    context "when the pipeline is a system pipeline" do
      let(:pipeline) { mock_pipeline_from_string("input { generator {} } output { null {} }", mock_settings("pipeline.system" => true)) }
      it "returns true" do
        expect(pipeline.system?).to be_truthy
      end
    end

    context "when the pipeline is not a system pipeline" do
      let(:pipeline) { mock_pipeline_from_string("input { generator {} } output { null {} }", mock_settings("pipeline.system" => false)) }
      it "returns true" do
        expect(pipeline.system?).to be_falsey
      end
    end
  end

  context "#reloadable?" do
    after do
      pipeline.close # close the queue
    end

    context "when all plugins are reloadable and pipeline is configured as reloadable" do
      let(:pipeline) { mock_pipeline_from_string("input { generator {} } output { null {} }", mock_settings("pipeline.reloadable" => true)) }

      it "returns true" do
        expect(pipeline.reloadable?).to be_truthy
      end
    end

    context "when the plugins are not reloadable and pipeline is configured as reloadable" do
      let(:pipeline) { mock_pipeline_from_string("input { stdin {} } output { null {} }", mock_settings("pipeline.reloadable" => true)) }

      it "returns true" do
        expect(pipeline.reloadable?).to be_falsey
      end
    end

    context "when all plugins are reloadable and pipeline is configured as non-reloadable" do
      let(:pipeline) { mock_pipeline_from_string("input { generator {} } output { null {} }", mock_settings("pipeline.reloadable" => false)) }

      it "returns true" do
        expect(pipeline.reloadable?).to be_falsey
      end
    end
  end
end
