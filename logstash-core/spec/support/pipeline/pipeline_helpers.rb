require "logstash/agent"
require "logstash/pipeline"
require "logstash/event"
require "stud/try"
require "rspec/expectations"
require "thread"

module PipelineHelpers

  class SpecSamplerInput < LogStash::Inputs::Base
    config_name "spec_sampler_input"

    def register
    end

    def run(queue)
      unless @@event.nil?
        batch = queue.get_new_batch
        @@event.each { |e| batch.push(e)}
        queue.push_batch(batch)
        @@event = nil
      end
    end

    def close
      @@event = nil
    end

    def self.set_event(event)
      @@event = event
    end
  end

  class SpecSamplerOutput < LogStash::Outputs::Base
    config_name "spec_sampler_output"

    def register
      @@seen = []
    end

    def multi_receive(events)
      @@seen += events
    end

    def self.seen
      @@seen
    end
  end

  def sample_one(sample_event, &block)
    name = sample_event.is_a?(String) ? sample_event : LogStash::Json.dump(sample_event)
    name = name[0..50] + "..." if name.length > 50

    before do
      LogStash::PLUGIN_REGISTRY.add(:input, "spec_sampler_input", SpecSamplerInput)
      LogStash::PLUGIN_REGISTRY.add(:output, "spec_sampler_output", SpecSamplerOutput)
    end

    describe "\"#{name}\"" do
      let(:pipeline) do
        cfg = "input { spec_sampler_input {} }\n" + config + "\noutput { spec_sampler_output {} }"
        settings = ::LogStash::SETTINGS.clone
        settings.set_value("queue.drain", true)
        settings.set_value("pipeline.workers", 1)
        config_part = org.logstash.common.SourceWithMetadata.new("config_string", "config_string", cfg)
        pipeline_config = LogStash::Config::PipelineConfig.new(LogStash::Config::Source::Local, :main, config_part, settings)
        LogStash::Pipeline.new(pipeline_config)
      end
      let(:event) do
        sample_event = [sample_event] unless sample_event.is_a?(Array)
        next sample_event.collect do |e|
          e = { "message" => e } if e.is_a?(String)
          next LogStash::Event.new(e)
        end
      end

      let(:results) do
        SpecSamplerInput.set_event event
        pipeline.run
        SpecSamplerOutput.seen
      end

      after do
        pipeline.close
      end

      subject {results.length > 1 ? results : results.first}

      it("when processed", &block)
    end
  end
end
