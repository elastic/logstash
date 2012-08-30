require "insist"
require "logstash/agent"
require "logstash/event"

module LogStash
  module RSpec
    if ENV["DEBUG"] 
      require "cabin"
      Cabin::Channel.get.level = :debug
    end

    def config(configstr)
      require "logstash/config/file"
      config = LogStash::Config::File.new(nil, configstr)
      agent = LogStash::Agent.new
      @inputs, @filters, @outputs = agent.instance_eval { parse_config(config) }

      [@inputs, @filters, @outputs].flatten.each do |plugin|
        plugin.register
      end
    end # def config

    def sample(event, &block)
      filters = @filters
      describe event do
        if event.is_a?(String)
          subject { LogStash::Event.new("@message" => [event]) }
        else
          subject { LogStash::Event.new(event) }
        end

        before :all do
          filters.each do |filter|
            filter.filter(subject)
          end
        end
        context("after processing", &block)
      end
    end # def sample
  end # module RSpec
end # module LogStash
