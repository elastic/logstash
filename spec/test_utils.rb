require "insist"
require "logstash/agent"
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
      default_type = @default_type || "default"
      default_tags = @default_tags || nil
      config = get_config
      agent = LogStash::Agent.new
      agent.instance_eval { parse_options(["--quiet"]) }
      @inputs, @filters, @outputs = agent.instance_eval { parse_config(config) }
      [@inputs, @filters, @outputs].flatten.each do |plugin|
        plugin.logger = $logger
        plugin.logger.level = :error
        plugin.register
      end

      filters = @filters
      name = event.to_s
      name = name[0..50] + "..." if name.length > 50
      describe "\"#{name}\"" do
        before :all do
          # Coerce to an array of LogStash::Event
          event = [event] unless event.is_a?(Array)
          event = event.collect do |e| 
            if e.is_a?(String)
              e = { "message" => e, "type" => default_type }
            end
            next LogStash::Event.new(e)
          end
          
          results = []
          count = 0
          event.each do |e|
            filters.each do |filter|
              next if e.cancelled?
              filter.filter(e) do |newevent|
                results << newevent unless e.cancelled?
              end
            end
            results << e unless e.cancelled?
          end

          # do any flushing.
          filters.each_with_index do |filter, i|
            if filter.respond_to?(:flush)
              # get any event from flushing
              list = filter.flush
              if list
                list.each do |e|
                  filters[i+1 .. -1].each do |f|
                    f.filter(e)
                  end
                  results << e unless e.cancelled?
                end
              end # if list
            end # filter.respond_to?(:flush)
          end # filters.each_with_index

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

    def get_config
      if @is_yaml
        require "logstash/config/file/yaml"
        config = LogStash::Config::File::Yaml.new(nil, @config_str)
      else
        require "logstash/config/file"
        config = LogStash::Config::File.new(nil, @config_str)
      end
    end # def get_config

    def agent(&block)
      @agent_count ||= 0
      require "logstash/agent"

      # scoping is hard, let's go shopping!
      config_str = @config_str
      describe "agent(#{@agent_count}) #{caller[1]}" do
        before :each do
          start = ::Time.now
          @agent = LogStash::Agent.new
          @agent.run(["--quiet", "-e", config_str])
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
