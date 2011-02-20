require "file/tail"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

class LogStash::Inputs::File < LogStash::Inputs::Base

  config_name "file"
  config :path => :string

  public
  def initialize(configs, output_queue)
    super

    @output_queue = output_queue
    @file_threads = {}
  end # def initialize

  public
  def run
    @configs.each do |type, url|
      glob = url.path
      if File.exists?(glob)
        files = [glob]
      else
        files = Dir.glob(glob)
      end
      files.each do |file|
        @file_threads[file] = Thread.new do
          JThread.currentThread().setName("inputs/file/reader:#{file}")
          watch(file, url, type, [type])
        end
      end
    end

    # http://jira.codehaus.org/browse/JRUBY-891
    # NOTE(petef): IO::Select is broken in jruby, so we start a
    # thread per file for now.
    while sleep 5
      # foo
    end

    #event = LogStash::Event.new({
    #  "@message" => event,
    #  "@type" => @type,
    #  "@tags" => @tags.clone,
    #})
    #event.source = url
    #@logger.debug(["Got event", event])
    #@callback.call(event)
  end # def run

  private
  def watch(file, source_url, type, tags)
    File.open(file, "r") do |f|
      f.extend(File::Tail)
      f.interval = 5
      f.backward(0)
      f.tail do |line|
        e = LogStash::Event.new({
          "@message" => line,
          "@type" => type,
          "@tags" => tags,
        })
        e.source = source_url.to_s
        @output_queue.push(e)
      end # f.tail
    end # File.open
  end
end # class LogStash::Inputs::File
