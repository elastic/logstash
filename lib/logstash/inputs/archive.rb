# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"

require "socket" # for Socket.gethostname

# By default, each event is assumed to be one line. If you would like
# to join multiple log lines into one event, you'll want to use the
# multiline codec.
class LogStash::Inputs::Archive < LogStash::Inputs::Base
  config_name "archive"
  milestone 1

  default :codec, "line"

  # The path(s) to the file(s) to use as an input.
  # You can use globs here, such as `/var/log/*.log`
  # Paths must be absolute and cannot be relative.
  #
  # You may also configure multiple paths. See an example
  # on the [Logstash configuration page](configuration#array).
  config :path, :validate => :array, :required => true

  # Exclusions (matched against the filename, not full path). Globs
  # are valid here, too. For example, if you have
  #
  #     path => "/var/log/*.gz"
  #
  # You might want to exclude 7zipped files:
  #
  #     exclude => "*.7z"
  config :exclude, :validate => :array

  # How often we expand globs to discover new files to watch.
  config :discover_interval, :validate => :number, :default => 15

  public
  def register
    require 'set'
    require 'zlib'

    @logger.info("Registering archive input", :path => @path)

    @exclude = [] unless defined? @exclude
    @path.each do |path|
      if Pathname.new(path).relative?
        raise ArgumentError.new("File paths must be absolute, relative path specified: #{path}")
      end
    end
  end # def register

  public
  def run(queue)
    processed_files = Set.new

    loop do
      @path.each do |globpath|
        filenames = Dir.glob(globpath)

        for filename in filenames
          next if processed_files.member?(filename)
          next if @exclude.any? { |rule| File.fnmatch?(rule, File.basename(filename)) }

          process(queue, filename)
          processed_files << filename
        end
      end

      sleep(@discover_interval)
    end

    finished
  end # def run

  private
  def process(queue, path)
    hostname = Socket.gethostname

    begin
      gz = Zlib::GzipReader.open(path)
    rescue Zlib::GzipFile::Error
      @logger.warn("A GZip-related error occured when processing #{path}. Ignoring...")
      return
    rescue
      @logger.warn("An error occured when processing #{path}. Ignoring...")
      return
    end

    gz.each_line do |line|
      @logger.debug? && @logger.debug("Received line", :path => path, :text => line)
      @codec.decode(line) do |event|
        decorate(event)
        event["host"] ||= hostname
        event["path"] ||= path
        queue << event
      end
    end
  end # def process
end # class LogStash::Inputs::File
