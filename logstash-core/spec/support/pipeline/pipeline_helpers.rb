require "logstash/agent"
require "logstash/pipeline"
require "logstash/event"
require "stud/try"
require "rspec/expectations"
require "thread"

module PipelineHelpers

  def sample_one(sample_event, &block)
    name = sample_event.is_a?(String) ? sample_event : LogStash::Json.dump(sample_event)
    name = name[0..50] + "..." if name.length > 50

    describe "\"#{name}\"" do
      let(:pipeline) { new_pipeline_from_string(config) }
      let(:event) do
        sample_event = [sample_event] unless sample_event.is_a?(Array)
        next sample_event.collect do |e|
          e = { "message" => e } if e.is_a?(String)
          next LogStash::Event.new(e)
        end
      end

      let(:results) do
        results = []
        pipeline.instance_eval { @filters.each(&:register) }

        event.each do |e|
          # filter call the block on all filtered events, included new events added by the filter
          pipeline.filter(e) { |filtered_event| results << filtered_event }
        end

        # flush makes sure to empty any buffered events in the filter
        pipeline.flush_filters(:final => true) { |flushed_event| results << flushed_event }

        results.select { |e| !e.cancelled? }
      end

      # starting at logstash-core 5.3 an initialized pipeline need to be closed
      after do
        pipeline.close if pipeline.respond_to?(:close)
      end

      subject { results.length > 1 ? results : results.first }

      it("when processed", &block)
    end
  end

  def new_pipeline_from_string(string)
      LogStash::Pipeline.new(string)
  end
end
