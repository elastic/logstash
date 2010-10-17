require 'lib/config/agent'
require 'lib/db/index'
require 'lib/program'
require 'grok'
require 'set'
require 'ap'
require 'socket' # for Socket.gethostname
require 'eventmachine'
require 'eventmachine-tail'
require 'em-http'

PROGRESS_AMOUNT = 500

class Reader < EventMachine::FileTail
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
end # class Reader

module LogStash; module Programs;
  class Agent < LogStash::Program
    public
    def initialize(options)
      super(options)
      @config = LogStash::Config::AgentConfig.new(options[:config])
      @config.merge!(options)
      @indexes = Hash.new { |h,k| h[k] = @config.logs[k] }

      @hostname = Socket.gethostname
      @needs_flushing = Set.new
      @count = 0
      @start = Time.now
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
      matched = false
      @config.logs.each do |name, log|
        begin
          entry = log.parse_entry(line)
          if entry
            entry["@SOURCE_FILE"] = path
            entry["@SOURCE_HOST"] = @hostname
            matched = true
            #ap entry
            index(name, entry)
            break
          end
        rescue LogStash::Log::LogParseError => e
          # ignore
        end
      end # @config.logs.each

      if !matched
        puts "nomatch in #{path}: #{line}"
      end
    end # def process

    private
    def publish(name, entry)
      # publish the entry
    end

    private
    def setup_watches
      #handler = EventMachine::FileGlobWatchTail.new(Reader, self)
      @config.watched_paths.each do |path|
        $logger.info("Watching #{path}")
        EventMachine::FileGlobWatchTail.new(path, Reader, interval=60,
                                            exclude=[], agent=self)
      end
    end
  end # class Agent
end; end # module LogStash::Programs
