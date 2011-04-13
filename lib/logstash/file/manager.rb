require "filewatch/buftok" # rubygem 'filewatch' - for BufferedTokenizer
require "filewatch/tailglob" # rubygem 'filewatch'
require "logstash/logging"
require "logstash/namespace"
require "logstash/util"
require "set"
require "socket" # for Socket.gethostname


class LogStash::File::Manager
  attr_reader :logger

  public
  def initialize(output_queue)
    @tail = FileWatch::TailGlob.new
    @watching = Hash.new
    @watching_lock = Mutex.new
    @file_threads = {}
    @main_thread = nil
    @output_queue = nil
    @hostname = Socket.gethostname

    self.logger = LogStash::Logger.new(STDOUT)
  end # def initialize

  public
  def logger=(logger)
    @logger = logger
    @tail.logger = logger
  end # def logger=

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
        @logger.debug(["watching file", {:path => path, :config => config}])

        # TODO(sissel): inputs/base should do this.
        config["tag"] ||= []
        #if !config["tag"].member?(config["type"])
          #config["tag"] << config["type"]
        #end

        # TODO(sissel): Need to support file rotation, globs, etc
        begin
          tailconf = { }
          if config.include?("exclude")
            tailconf[:exclude] = config["exclude"]
          end

          # Register a @tail callback for new paths
          @tail.tail(path, tailconf) do |fullpath|
            @logger.info("New file found: #{fullpath}")
            @watching[fullpath] = config
          end
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
    LogStash::Util::set_thread_name(self.class.name)
    @buffers = Hash.new { |h,k| h[k] = BufferedTokenizer.new }
    begin
      @tail.subscribe do |path, data|
        # TODO(sissel): 'path' might not be watched since we could
        # be watching a glob.
        #
        # Maybe extend @tail.tail to accept a extra args that it will
        # pass to subscribe's callback?
        config = @watching[path]
        @logger.debug(["Event from tail", { :path => path, :config => config }])
        @buffers[path].extract(data).each do |line|
          e = LogStash::Event.new({
            "@message" => line,
            "@type" => config["type"],
            "@tags" => config["tag"].dup,
          })
          e.source = "file://#{@hostname}#{path}"
          @logger.debug(["New event from file input", path, e])
          @output_queue << e
        end
      end
    rescue Exception => e
      @logger.warn(["Exception in #{self.class} thread, retrying", e, e.backtrace])
      sleep 0.3
      retry
    end
  end # def watcher
end # class LogStash::File::Manager
