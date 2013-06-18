require "logstash/inputs/base"
require "logstash/namespace"

require "pathname"
require "socket" # for Socket.gethostname

# Stream events from files.
#
# By default, each event is assumed to be one line. If you
# want to join lines, you'll want to use the multiline filter.
#
# Files are followed in a manner similar to "tail -0F". File rotation
# is detected and handled by this input.
class LogStash::Inputs::File < LogStash::Inputs::Base
  config_name "file"
  milestone 2

  # The path to the file to use as an input.
  # You can use globs here, such as `/var/log/*.log`
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
  # position of monitored log files). The default will write
  # sincedb files to some path matching "$HOME/.sincedb*"
  config :sincedb_path, :validate => :string

  # How often to write a since database with the current position of
  # monitored log files.
  config :sincedb_write_interval, :validate => :number, :default => 15

  # Choose where logstash starts initially reading files - at the beginning or
  # at the end. The default behavior treats files like live streams and thus
  # starts at the end. If you have old data you want to import, set this
  # to 'beginning'
  #
  # This option only modifieds "first contact" situations where a file is new
  # and not seen before. If a file has already been seen before, this option
  # has no effect.
  config :start_position, :validate => [ "beginning", "end"], :default => "end"

  public
  def register
    require "addressable/uri"
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

    @path.each do |path|
      if Pathname.new(path).relative?
        raise ArgumentError.new("File paths must be absolute, relative path specified: #{path}")
      end
    end

    if @sincedb_path.nil?
      if ENV["HOME"].nil?
        @logger.error("No HOME environment variable set, I don't know where " \
                      "to keep track of the files I'm watching. Either set " \
                      "HOME in your environment, or set sincedb_path in " \
                      "in your logstash config for the file input with " \
                      "path '#{@path.inspect}'")
        raise # TODO(sissel): HOW DO I FAIL PROPERLY YO
      end

      # Join by ',' to make it easy for folks to know their own sincedb
      # generated path (vs, say, inspecting the @path array)
      @sincedb_path = File.join(ENV["HOME"], ".sincedb_" + Digest::MD5.hexdigest(@path.join(",")))

      # Migrate any old .sincedb to the new file (this is for version <=1.1.1 compatibility)
      old_sincedb = File.join(ENV["HOME"], ".sincedb")
      if File.exists?(old_sincedb)
        @logger.info("Renaming old ~/.sincedb to new one", :old => old_sincedb,
                     :new => @sincedb_path)
        File.rename(old_sincedb, @sincedb_path)
      end

      @logger.info("No sincedb_path set, generating one based on the file path",
                   :sincedb_path => @sincedb_path, :path => @path)
    end

    @tail_config[:sincedb_path] = @sincedb_path

    if @start_position == "beginning"
      @tail_config[:start_new_files_at] = :beginning
    end
  end # def register

  public
  def run(queue)
    @tail = FileWatch::Tail.new(@tail_config)
    @tail.logger = @logger
    @path.each { |path| @tail.tail(path) }
    hostname = Socket.gethostname

    @tail.subscribe do |path, line|
      #source = Addressable::URI.new(:scheme => "file", :host => hostname, :path => path).to_s
      source = "file://#{hostname}/#{path.gsub("\\","/")}"
      @logger.debug? && @logger.debug("Received line", :path => path, :line => line)
      @codec.decode(line) do |event|
        event["source"] = source
      end
    end
    finished
  end # def run

  public
  def teardown
    @tail.quit
  end # def teardown
end # class LogStash::Inputs::File
