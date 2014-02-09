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

  #default :codec, "line"
  default :codec, "plain"
  
  config :path, :validate => :string, :required => true
  config :prefix, :validate => :string
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
      #@watchkey = 
      @javapath.register(@watcher,
                         java.nio.file.StandardWatchEventKinds::ENTRY_MODIFY,
                         java.nio.file.StandardWatchEventKinds::ENTRY_CREATE)
    rescue java.lang.Exception => e
      e.printStackTrace
      raise e
      #$stderr.print "** JAVA: #{e}n"
    end
  end # def register

  def run(queue) 
    while true
      begin
        # Based on some testing, there is no way to interrupt an IO.sysread nor
        # IO.select call in JRuby. Bummer :(
        #data = $stdin.sysread(16384)
        watchkey = @watcher.take
        if (watchkey)
          begin
            watchkey.pollEvents.each do |watchevent|
              if (watchevent)

                p = watchevent.context
                #$stdout.write("** P: " + p.toString)
                if ((@prefix.nil? || p.getFileName.toString.start_with?(@prefix)) && (@suffix.nil? || p.getFileName.toString.end_with?(@suffix)))

                  reader = java.nio.file.Files.newBufferedReader(@javapath.resolve(p), @charset)
                  while (reader.ready)
                    @codec.decode(reader.readLine) do |event|
                      decorate(event)
                      event["host"] = @host
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
            #$stderr.print "** JAVA: #{e}n"
          end

        end
      rescue EOFError, LogStash::ShutdownSignal
        # stdin closed or a requested shutdown
        break
      end
    end # while true
    finished
  end # def run

  public
  def teardown
    @watcher.close
    @logger.debug("nio2path shutting down.")
    #$stdin.close rescue nil
    finished
  end # def teardown
end # class LogStash::Inputs::Stdin
