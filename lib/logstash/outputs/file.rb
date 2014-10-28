# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/base"
require "logstash/errors"
require "zlib"

# This output will write events to files on disk. You can use fields
# from the event as parts of the filename and/or path.
class LogStash::Outputs::File < LogStash::Outputs::Base

  config_name "file"
  milestone 2

  # The path to the file to write. Event fields can be used here,
  # like "/var/log/logstash/%{host}/%{application}"
  # One may also utilize the path option for date-based log
  # rotation via the joda time format. This will use the event
  # timestamp.
  # E.g.: path => "./test-%{+YYYY-MM-dd}.txt" to create
  # ./test-2013-05-29.txt
  #
  # If you use an absolute path you cannot start with a dynamic string.
  # E.g: /%{myfield}/, /test-%{myfield}/ are not valid paths
  config :path, :validate => :string, :required => true

  # The maximum size of file to write. When the file exceeds this
  # threshold, it will be rotated to the current filename + ".1"
  # If that file already exists, the previous .1 will shift to .2
  # and so forth.
  #
  # NOT YET SUPPORTED
  config :max_size, :validate => :string

  # The format to use when writing events to the file. This value
  # supports any string and can include %{name} and other dynamic
  # strings.
  #
  # If this setting is omitted, the full json representation of the
  # event will be written as a single line.
  config :message_format, :validate => :string

  # Flush interval (in seconds) for flushing writes to log files.
  # 0 will flush on every message.
  config :flush_interval, :validate => :number, :default => 2

  # Gzip the output stream before writing to disk.
  config :gzip, :validate => :boolean, :default => false

  # If the event try to create a file outside of the extracted file root
  # we will tag the message and save it to @filepath_error.
  config :tag_on_failure, :validate => :array, :default => ["_filepath_failure"]

  # If the generated path is invalid, the events will be saved
  # into this file and inside the defined path.
  config :filename_failure, :validate => :string, :default => '_filepath_failures'

  public
  def register
    require "fileutils" # For mkdir_p

    workers_not_supported

    @files = {}
    
    @path = File.expand_path(path)

    validate_path

    if interpolated_path?
      @file_root = extract_file_root
      @failure_path = File.join(@file_root, @filename_failure)
    end

    now = Time.now
    @last_flush_cycle = now
    @last_stale_cleanup_cycle = now
    @flush_interval = @flush_interval.to_i
    @stale_cleanup_interval = 10
  end # def register

  private
  def validate_path
    root_directory = @path.split(File::SEPARATOR).select { |item| !item.empty? }.shift

    if (root_directory =~ /%\{[^}]+\}/) != nil
      @logger.error("File: The starting part of the path should not be dynamic.", :path => @path)
      raise LogStash::ConfigurationError.new("The starting part of the path should not be dynamic.")
    end
  end

  public
  def receive(event)
    return unless output?(event)

    log_path = generate_filepath(event)

    if interpolated_path? && !inside_file_root?(log_path)
      tag_as_filepath_failure(event)
      log_path = @failure_path
    end

    output = format_message(event)
    write_event(log_path, output)
  end # def receive

  private
  def tag_as_filepath_failure(event)
    event["tags"] ||= []
    @tag_on_failure.each do |tag|
      event["tags"] << tag unless event["tags"].include?(tag)
    end
  end

  private
  def inside_file_root?(log_path)
    target_file = File.expand_path(log_path)
    return target_file.start_with?("#{@file_root.to_s}/")
  end

  private
  def write_event(log_path, event)
    @logger.debug("File, writing event to file.", :filename => log_path)
    fd = open(log_path)

    # TODO(sissel): Check if we should rotate the file.

    fd.write(event)
    fd.write("\n")

    flush(fd)
    close_stale_files
  end

  private
  def generate_filepath(event)
    event.sprintf(@path)
  end

  private
  def interpolated_path?
    path =~ /%\{[^}]+\}/
  end

  def format_message(event)
    if @message_format
      event.sprintf(@message_format)
    else
      event.to_json
    end
  end

  def extract_file_root
    extracted_path = File.expand_path(path.gsub(/%{.+/, ''))
    Pathname.new(extracted_path).expand_path
  end

  def teardown
    @logger.debug("Teardown: closing files")
    @files.each do |path, fd|
      begin
        fd.close
        @logger.debug("Closed file #{path}", :fd => fd)
      rescue Exception => e
        @logger.error("Exception while flushing and closing files.", :exception => e)
      end
    end
    finished
  end

  private
  def flush(fd)
    if flush_interval > 0
      flush_pending_files
    else
      fd.flush
    end
  end

  # every flush_interval seconds or so (triggered by events, but if there are no events there's no point flushing files anyway)
  def flush_pending_files
    return unless Time.now - @last_flush_cycle >= flush_interval
    @logger.debug("Starting flush cycle")
    @files.each do |path, fd|
      @logger.debug("Flushing file", :path => path, :fd => fd)
      fd.flush
    end
    @last_flush_cycle = Time.now
  end

  # every 10 seconds or so (triggered by events, but if there are no events there's no point closing files anyway)
  def close_stale_files
    now = Time.now
    return unless now - @last_stale_cleanup_cycle >= @stale_cleanup_interval
    @logger.info("Starting stale files cleanup cycle", :files => @files)
    inactive_files = @files.select { |path, fd| not fd.active }
    @logger.debug("%d stale files found" % inactive_files.count, :inactive_files => inactive_files)
    inactive_files.each do |path, fd|
      @logger.info("Closing file %s" % path)
      fd.close
      @files.delete(path)
    end
    # mark all files as inactive, a call to write will mark them as active again
    @files.each { |path, fd| fd.active = false }
    @last_stale_cleanup_cycle = now
  end

  def open(path)
    return @files[path] if @files.include?(path) and not @files[path].nil?

    @logger.info("Opening file", :path => path)

    dir = File.dirname(path)
    if !Dir.exists?(dir)
      @logger.info("Creating directory", :directory => dir)
      FileUtils.mkdir_p(dir)
    end

    # work around a bug opening fifos (bug JRUBY-6280)
    stat = File.stat(path) rescue nil
    if stat and stat.ftype == "fifo" and RUBY_PLATFORM == "java"
      fd = java.io.FileWriter.new(java.io.File.new(path))
    else
      fd = File.new(path, "a")
    end
    if gzip
      fd = Zlib::GzipWriter.new(fd)
    end
    @files[path] = IOWriter.new(fd)
  end
end # class LogStash::Outputs::File

# wrapper class
class IOWriter
  def initialize(io)
    @io = io
  end
  def write(*args)
    @io.write(*args)
    @active = true
  end
  def flush
    @io.flush
    if @io.class == Zlib::GzipWriter
      @io.to_io.flush
    end
  end
  def method_missing(method_name, *args, &block)
    if @io.respond_to?(method_name)
      @io.send(method_name, *args, &block)
    else
      super
    end
  end
  attr_accessor :active
end
