require "filewatch/tail" # rubygem 'filewatch'
require "logstash/namespace"
require "logstash/logging"
require "set"
require "socket" # for Socket.gethostname

require "eventmachine" # for BufferedTokenizer

class LogStash::File::Manager
  attr_accessor :logger

  public
  def initialize(output_queue)
    @tail = FileWatch::Tail.new
    @watching = Hash.new
    @watching_lock = Mutex.new
    @file_threads = {}
    @main_thread = nil
    @output_queue = nil
    @logger = Logstash::Logger.new(STDOUT)
    @hostname = Socket.gethostname
  end # def initialize

  public
  def run(queue)
    @output_queue = queue
    @main_thread ||= Thread.new { watcher }
  end

  public
  def watch(paths, config)
    @watching_lock.synchronize do
      paths.each do |path|
        if @watching[path]
          raise ValueError, "cannot watch the same path #{path} more than once"
        end
        @logger.debug(["watching file", {:path => path}])

        @watching[path] = config

        # TODO(sissel): inputs/base should do this.
        config["tag"] ||= []
        if !config["tag"].member?(config["type"])
          config["tag"] << config["type"]
        end

        # TODO(sissel): Need to support file rotation, globs, etc
        begin
          @tail.watch(path, :modify)
          # TODO(sissel): Make FileWatch emit real exceptions
        rescue RuntimeError
          @logger.info("Failed to start watch on #{path.inspect}")
          # Ignore.
        end
      end
    end
  end

  private
  def watcher
    JThread.currentThread().setName(self.class.name)
    @buffers = Hash.new { |h,k| h[k] = BufferedTokenizer.new }
    begin
      @tail.subscribe do |path, data|
        config = @watching[path]
        @buffers[path].extract(data).each do |line|
          e = LogStash::Event.new({
            "@message" => line,
            "@type" => config["type"],
            "@tags" => config["tag"].dup,
          })
          e.source = "file://#{@hostname}/#{path}"
          @logger.debug(["New event from file input", path, e])
          @output_queue << e
        end
      end
    rescue Exception => e
      @logger.warn(["Exception in #{self.class} thread, retrying", e])
      sleep 0.3
      retry
    end
  end # def watcher
end # class LogStash::File::Manager
