require "insist"
require "logstash/agent"
require "logstash/event"

if RUBY_VERSION < "1.9.2"
  $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
  $stderr.puts "Options for fixing this: "
  $stderr.puts "  * If doing 'ruby bin/logstash ...' add --1.9 flag to 'ruby'"
  $stderr.puts "  * If doing 'java -jar ... ' add -Djruby.compat.version=RUBY1_9 to java flags"
  raise LoadError
end

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
        it("when processed", &block)
      end
    end # def sample
  end # module RSpec
end # module LogStash
