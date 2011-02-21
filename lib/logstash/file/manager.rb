require "file/tail"
require "logstash/namespace"
require "set"
require "socket" # for Socket.gethostname

class LogStash::File::Manager
  attr_accessor :logger

  public
  def initialize(output_queue)
    @watching = Hash.new
    @watching_lock = Mutex.new
    @file_threads = {}
    @main_thread = nil
    @output_queue = nil
    @logger = Logger.new(STDOUT)
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
      paths.each do |p|
        if @watching[p]
          raise ValueError, "cannot watch the same path #{p} more than once"
        end

        @watching[p] = config
      end
    end
  end

  private
  def watcher
    JThread.currentThread().setName("filemanager")
    begin
      while true
        @watching.each do |path, config|
          next if @file_threads[path]

          files = Dir.glob(path)
          files.each do |g_path|
            next if @file_threads[g_path]
            @file_threads[g_path] = Thread.new { file_watch(g_path, config) }
          end
        end

        sleep(@file_threads.length > 0 ? 30 : 5)
      end
    rescue Exception => e
      @logger.warn(["Exception in #{self.class} thread, retrying", e])
      retry
    end
  end

  private
  def file_watch(path, config)
    JThread.currentThread().setName("input|file|file:#{path}")
    @logger.debug(["watching file", {:path => path}])

    config["tag"] ||= []
    if !config["tag"].member?(config["type"])
      config["tag"] << config["type"]
    end

    File.open(path, "r") do |f|
      f.extend(File::Tail)
      f.interval = 5
      f.backward(0)
      f.tail do |line|
        e = LogStash::Event.new({
          "@message" => line,
          "@type" => config["type"],
          "@tags" => config["tag"].dup,
        })
        e.source = "file://#{@hostname}/#{path}"
        @output_queue << e
      end # f.tail
    end # File.open
  end
end # class LogStash::File::Manager
