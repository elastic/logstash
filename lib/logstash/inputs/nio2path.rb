# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Read events from a Java NIO.2 Path.
#
# By default, each event is assumed to be one line. If you
# want to join lines, you'll want to use the multiline filter.
class LogStash::Inputs::Nio2Path < LogStash::Inputs::Base
  config_name "nio2path"
  milestone 1

  default :codec, "plain"
  
  # The directory to watch for files.  Must be a directory!
  config :path, :validate => :string, :required => true
  
  # Prefix on filenames in the watched directory.
  # "access" for example
  config :prefix, :validate => :string

  # Suffix on filenames in the watched directory.
  # ".log" for example
  config :suffix, :validate => :string

  #config :start_position, :validate => [ "beginning", "end"], :default => "end"

  public
  def register
    @host = Socket.gethostname
    begin
      @javapath = java.nio.file.Paths.get(@path)
      #@file = java.nio.file.Files.readAllLines(@path)
      @charset = java.nio.charset.Charset.forName("UTF-8")
      @watcher = @javapath.getFileSystem.newWatchService
      @javapath.register(@watcher,
                         java.nio.file.StandardWatchEventKinds::ENTRY_MODIFY,
                         java.nio.file.StandardWatchEventKinds::ENTRY_CREATE)
    rescue java.lang.Exception => e
      e.printStackTrace
      raise e
    end
  end # def register

  def run(queue) 
    while true
      begin
        watchkey = @watcher.take
        if (watchkey)
          begin
            watchkey.pollEvents.each do |watchevent|
              if (watchevent)

                p = watchevent.context
                if ((@prefix.nil? || p.getFileName.toString.start_with?(@prefix)) && (@suffix.nil? || p.getFileName.toString.end_with?(@suffix)))

                  reader = java.nio.file.Files.newBufferedReader(@javapath.resolve(p), @charset)
                  while (reader.ready)
                    @codec.decode(reader.readLine) do |event|
                      decorate(event)
                      event["host"] = @host
                      event["path"] = p.toAbsolutePath.toString
                      queue << event
                    end
                  end
                  reader.close
                end
              end
            end
            watchkey.reset
          rescue java.lang.Exception => e
            e.printStackTrace
            raise e
          end

        end
      rescue EOFError, LogStash::ShutdownSignal
        break
      end
    end # while true
    finished
  end # def run

  public
  def teardown
    @watcher.close
    @logger.debug("nio2path shutting down.")
    finished
  end # def teardown
end # class LogStash::Inputs::Nio2Path
