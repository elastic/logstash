require "logstash/agent"
require "logstash/pipeline"
require "logstash/event"

module LogStashHelper

  def config(configstr)
    let(:config) { configstr }
  end # def config

  def type(default_type)
    let(:default_type) { default_type }
  end

  def tags(*tags)
    let(:default_tags) { tags }
    puts "Setting default tags: #{tags}"
  end

  def sample(sample_event, &block)
    name = sample_event.is_a?(String) ? sample_event : LogStash::Json.dump(sample_event)
    name = name[0..50] + "..." if name.length > 50

    describe "\"#{name}\"" do
      let(:pipeline) { LogStash::Pipeline.new(config) }
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
          pipeline.filter(e) {|new_event| results << new_event }
        end

        pipeline.flush_filters(:final => true) do |e|
          results << e unless e.cancelled?
        end

        results
      end

      subject { results.length > 1 ? results: results.first }

      it("when processed", &block)
    end
  end # def sample

  def input(&block)
    it "inputs" do
      pipeline = LogStash::Pipeline.new(config)
      queue = Queue.new
      pipeline.instance_eval do
        @output_func = lambda { |event| queue << event }
      end
      block.call(pipeline, queue)
      pipeline.shutdown
    end
  end # def input

  def agent(&block)

    it("agent(#{caller[0].gsub(/ .*/, "")}) runs") do
      pipeline = LogStash::Pipeline.new(config)
      pipeline.run
      block.call
    end
  end # def agent

end # module LogStash

