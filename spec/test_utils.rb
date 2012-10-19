require "insist"
require "logstash/event"
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

module LogStash
  module RSpec
    
    def config(configstr)
      @config_str = configstr
    end # def config

    def sample(event, &block)
      require "logstash/config/file"
      config = LogStash::Config::File.new(nil, @config_str)
      agent = LogStash::Agent.new
      @inputs, @filters, @outputs = agent.instance_eval { parse_config(config) }
      [@inputs, @filters, @outputs].flatten.each do |plugin|
        plugin.register
      end

      multiple_events = event.is_a?(Array)

      filters = @filters
      name = event.to_s
      name = name[0..50] + "..." if name.length > 50
      describe "\"#{name}\"" do
        before :all do
          # Coerce to an array of LogStash::Event
          event = [event] unless event.is_a?(Array)
          event = event.collect do |e| 
            if e.is_a?(String)
              LogStash::Event.new("@message" => e)
            else
              LogStash::Event.new(e)
            end
          end
          
          results = []
          event.each do |e|
            filters.each do |filter|
              next if e.cancelled?
              filter.filter(e)
            end
            results << e unless e.cancelled?
          end

          filters.select { |f| f.respond_to?(:flush) }.each do |filter|
            event = filter.flush 
            results += event if event
          end

          @results = results
        end
        if multiple_events
          subject { @results }
        else
          subject { @results.first }
        end
        it("when processed", &block)
      end
    end # def sample

    def input(&block)
      require "logstash/config/file"
      config = LogStash::Config::File.new(nil, @config_str)
      agent = LogStash::Agent.new
      it "looks good" do
        inputs, filters, outputs = agent.instance_eval { parse_config(config) }
        block.call(inputs)
      end
    end # def input

    def agent(&block)
      @agent_count ||= 0
      require "logstash/agent"

      # scoping is hard, let's go shopping!
      config_str = @config_str
      describe "agent(#{@agent_count}) #{caller[1]}" do
        before :all do
          start = ::Time.now
          @agent = LogStash::Agent.new
          @agent.run(["-e", config_str])
          @agent.wait
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

