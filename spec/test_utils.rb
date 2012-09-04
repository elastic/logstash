require "insist"
require "logstash/event"
require "insist"
require "stud/try"

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
          start = Time.now
          @agent = LogStash::Agent.new
          @agent.run(["-e", config_str])
          @agent.wait
          @duration = Time.now - start
        end
        it("looks good", &block)
      end
      @agent_count += 1
    end # def agent
  end # module RSpec
end # module LogStash
