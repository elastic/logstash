require "insist"
require "logstash/agent"
require "logstash/pipeline"
require "logstash/event"
require "logstash/logging"
require "insist"
require "stud/try"

$TESTING = true
if RUBY_VERSION < "1.9.2"
  $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
  $stderr.puts "Options for fixing this: "
  $stderr.puts "  * If doing 'ruby bin/logstash ...' add --1.9 flag to 'ruby'"
  $stderr.puts "  * If doing 'java -jar ... ' add -Djruby.compat.version=RUBY1_9 to java flags"
  raise LoadError
end

$logger = LogStash::Logger.new(STDOUT)
if ENV["TEST_DEBUG"]
  $logger.level = :debug
else
  $logger.level = :error
end

module LogStash
  module RSpec
    def config(configstr)
      @config_str = configstr
    end # def config

    def config_yaml(configstr)
      @config_str = configstr
      @is_yaml = true
    end

    def type(default_type)
      @default_type = default_type
    end
    
    def tags(*tags)
      @default_tags = tags
      puts "Setting default tags: #{@default_tags}"
    end

    def sample(event, &block)
      pipeline = LogStash::Pipeline.new(@config_str)

      name = event.is_a?(String) ? event : event.to_json
      name = name[0..50] + "..." if name.length > 50

      describe "\"#{name}\"" do
        before :each do
          # Coerce to an array of LogStash::Event
          event = [event] unless event.is_a?(Array)
          event = event.collect do |e| 
            e = { "message" => e } if e.is_a?(String)
            next LogStash::Event.new(e)
          end

          results = []
          count = 0
          pipeline.instance_eval { @filters.each(&:register) }
          event.each do |e|
            extra = []
            pipeline.filter(e) do |new_event|
              extra << new_event
            end
            results << e if !e.cancelled?
            results += extra.reject(&:cancelled?)
          end

          # TODO(sissel): pipeline flush needs to be implemented.
          #results += pipeline.flush
          @results = results
        end # before :all

        subject { @results.length > 1 ? @results: @results.first }
        it("when processed", &block)
      end
    end # def sample

    def input(&block)
      config = get_config
      agent = LogStash::Agent.new
      agent.instance_eval { parse_options(["--quiet"]) }
      it "looks good" do
        inputs, filters, outputs = agent.instance_eval { parse_config(config) }
        block.call(inputs)
      end
    end # def input

    def agent(&block)
      @agent_count ||= 0
      require "logstash/pipeline"

      # scoping is hard, let's go shopping!
      config_str = @config_str
      describe "agent(#{@agent_count}) #{caller[1]}" do
        before :each do
          start = ::Time.now
          pipeline = LogStash::Pipeline.new(config_str)
          pipeline.run
          @duration = ::Time.now - start
        end
        it("looks good", &block)
      end
      @agent_count += 1
    end # def agent

  end # module RSpec
end # module LogStash

class Shiftback
  def initialize(&block)
    @block = block
  end

  def <<(event)
    @block.call(event)
  end
end # class Shiftback
