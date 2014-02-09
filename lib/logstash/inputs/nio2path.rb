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
  config :prefix, :validate => :string, :default => ""

  # Suffix on filenames in the watched directory.
  # ".log" for example
  config :suffix, :validate => :string, :default => ""

  config :start_position, :validate => [ "beginning", "end"], :default => "end"

  public
  def register
    @host = Socket.gethostname
    @charset = java.nio.charset.Charset.forName("UTF-8")
    @readers = {}
    begin
      @javapath = java.nio.file.Paths.get(@path)
      java.nio.file.Files.newDirectoryStream(@javapath, @prefix + "*" + @suffix).each do |file|
        if (!java.nio.file.Files.isDirectory(file))
          @readers[file.getFileName.toString] = java.nio.file.Files.newBufferedReader(file, @charset)
        end
      end
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
    @readers.each do |file, rdr|
      if (@start_position == "end")
        rdr.skip(java.nio.file.Files.size(@javapath.resolve(file)))
      else
        while (rdr.ready)
          @codec.decode(rdr.readLine) do |event|
            decorate(event)
            event["host"] = @host
            event["path"] = @javapath.resolve(file).toAbsolutePath.toString
            queue << event
          end
        end
      end
    end
    while true
      begin
        watchkey = @watcher.take
        if (watchkey)
          begin
            watchkey.pollEvents.each do |watchevent|
              if (watchevent)

                p = watchevent.context
                if ((@prefix.nil? || p.getFileName.toString.start_with?(@prefix)) && (@suffix.nil? || p.getFileName.toString.end_with?(@suffix)))

                  reader = @readers[p.getFileName.toString]
                  while (reader.ready)
                    @codec.decode(reader.readLine) do |event|
                      decorate(event)
                      event["host"] = @host
                      event["path"] = p.toAbsolutePath.toString
                      queue << event
                    end
                  end
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
