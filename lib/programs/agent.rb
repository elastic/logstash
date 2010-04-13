require 'lib/config/agent'
require 'lib/program'
require 'lib/file/tail'
require 'grok'
require 'set'
require 'ap'
require 'socket' # for Socket.gethostname
require 'eventmachine'
require 'eventmachine-tail'

class GrokReader < EventMachine::FileTail
  def initialize(path, agent)
    super(path)
    @agent = agent
    @buffer = BufferedTokenizer.new
  end

  def receive_data(data)
    @buffer.extract(data).each do |line|
      @agent.process(path, line)
    end
  end # def receive_data

end # class GrokReader

module LogStash; module Programs;
  class Agent < LogStash::Program
    public
    def initialize(options)
      super(options)
      @config = LogStash::Config::AgentConfig.new(options[:config])
      @config.merge!(options)
      @indexes = Hash.new { |h,k| h[k] = @config.logs[k].get_index }
      @hostname = Socket.gethostname
      @needs_flushing = Set.new
    end

    public
    def run
      EventMachine.run do
        super
        setup_watches

        EventMachine.add_periodic_timer(1) do
          flush_indexes
        end
        ap @options
      end # EventMachine.run
    end # def run

    public
    def process(path, line)
      @config.logs.each do |name, log|
        begin
          entry = log.parse_entry(line)
          if entry
            entry["@SOURCE_FILE"] = path
            entry["@SOURCE_HOST"] = @hostname
            puts "match #{name} in #{path}: #{line}"
            index(name, entry)
            break
          end
        rescue LogStash::Log::LogParseError => e
          # ignore
        end
      end # @logs.each
    end # def process

    private
    def index(name, entry)
      @indexes[name] << entry
      @needs_flushing << name
    end

    private
    def setup_watches
      handler = EventMachine::FileGlobWatchTail.new(GrokReader, self)
      @config.watched_paths.each do |path|
        $logger.warn("Watching #{path}")
        EventMachine::FileGlobWatch.new(path, handler)
      end
    end

    private
    def flush_indexes
      @needs_flushing.each do |name|
        $logger.warn("Flushing #{name}")
        @indexes[name].flush
      end
      @needs_flushing.clear
    end
  end # class Agent
end; end # module LogStash::Programs
