require "logstash/inputs/base"
require "logstash/namespace"

require "pathname"
require "socket" # for Socket.gethostname

require "addressable/uri"

# Stream events from files.
#
# By default, each event is assumed to be one line. If you
# want to join lines, you'll want to use the multiline filter.
#
# Files are followed in a manner similar to "tail -0F". File rotation
# is detected and handled by this input.
class LogStash::Inputs::File < LogStash::Inputs::Base
  config_name "file"
  plugin_status "beta"

  # The path to the file to use as an input.
  # You can use globs here, such as "/var/log/*.log"
  # Paths must be absolute and cannot be relative.
  config :path, :validate => :array, :required => true

  # Exclusions (matched against the filename, not full path). Globs
  # are valid here, too. For example, if you have
  #
  #     path => "/var/log/*"
  #
  # you might want to exclude gzipped files:
  #
  #     exclude => "*.gz"
  config :exclude, :validate => :array

  # How often we stat files to see if they have been modified. Increasing
  # this interval will decrease the number of system calls we make, but
  # increase the time to detect new log lines.
  config :stat_interval, :validate => :number, :default => 1

  # How often we expand globs to discover new files to watch.
  config :discover_interval, :validate => :number, :default => 15

  # Where to write the since database (keeps track of the current
  # position of monitored log files). Defaults to the value of
  # environment variable "$SINCEDB_PATH" or "$HOME/.sincedb".
  config :sincedb_path, :validate => :string

  # How often to write a since database with the current position of
  # monitored log files.
  config :sincedb_write_interval, :validate => :number, :default => 15

  public
  def initialize(params)
    super
    
    @path.each do |path|
      if Pathname.new(path).relative?
        raise ArgumentError.new("File paths must be absolute, relative path specified: #{path}")
      end
    end
  end

  public
  def register
    require "filewatch/tail"
    require "digest/md5"
    LogStash::Util::set_thread_name("input|file|#{path.join(":")}")
    @logger.info("Registering file input", :path => @path)

    @tail_config = {
      :exclude => @exclude,
      :stat_interval => @stat_interval,
      :discover_interval => @discover_interval,
      :sincedb_write_interval => @sincedb_write_interval,
      :logger => @logger,
    }

    if @sincedb_path.nil?
      # TODO(sissel): migrate .sincedb file if it exists
      if ENV["HOME"].nil?
        @logger.error("No HOME environment variable set, I don't know where " \
                      "keep track of the files I'm watching. Either set " \
                      "HOME in your environment, or set sincedb_path in " \
                      "in your logstash config for the file input with " \
                      "path '#{@path.inspect}'")
        raise # TODO(sissel): HOW DO I FAIL PROPERLY YO
      end

      # Join by ',' to make it easy for folks to know their own sincedb
      # generated path (vs, say, inspecting the @path array)
      @sincedb_path = File.join(ENV["HOME"], Digest::MD5.hexdigest(@path.join(",")))
      @logger.info("No sincedb_path set, generating one based on the path",
                   :sincedb_path => @sincedb_path)
    end

    @tail_config[:sincedb_path] = @sincedb_path
  end # def register

  public
  def run(queue)
    tail = FileWatch::Tail.new(@tail_config)
    tail.logger = @logger
    @path.each { |path| tail.tail(path) }
    hostname = Socket.gethostname

    tail.subscribe do |path, line|
      source = Addressable::URI.new(:scheme => "file", :host => hostname, :path => path).to_s
      @logger.debug("Received line", :path => path, :line => line)
      e = to_event(line, source)
      if e
        queue << e
      end
    end
  end # def run
end # class LogStash::Inputs::File
