# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/base"
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
  config :path, :validate => :string, :required => true

  # The maximum size in kB of file to write. When the file exceeds this
  # threshold, it will be rotated to the current filename + ".1"
  # If that file already exists, the previous .1 will shift to .2
  # and so forth.
  #
  # if this setting is omitted or 0, no file rotation is performed.
  config :max_size, :validate => :number, :default => 0

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

  # The maximum number of rotation files to keep. If the maximum
  # number is reached files with an older modification time are retired (deleted).
  # This setting is active only if a log rotation - configured with the
  # max_size setting - is active too.
  #
  # If this setting is omitted or 0, no rotation files are retired.
  config :max_files, :validate => :number, :default => 0

  public
  def register
    require "fileutils" # For mkdir_p

    workers_not_supported

    @files = {}
    now = Time.now
    @last_flush_cycle = now
    @last_stale_cleanup_cycle = now
    flush_interval = @flush_interval.to_i
    @stale_cleanup_interval = 10
    # calc the max size in bytes
    @max_size_bytes = @max_size.to_i * 1024
  end # def register

  public
  def receive(event)
    return unless output?(event)

    path = event.sprintf(@path)
    fd = open(path)

    # # Check if we should rotate the file.
    if @max_size_bytes != nil and @max_size_bytes > 0 and fd.size >= @max_size_bytes
      # get the rotation file name and path
      new_path = get_rotation_file_name(path)
      if new_path != path
        # close the file, rename it to the rotation file path and reopen the
        # original file again.
        @logger.debug("Rotating file #{path} to #{new_path}")
        fd.flush()
        fd.close()
        @files.delete(path)
        File.rename(path, new_path)
        fd = open(path)
      end

      #delete older files if max_files roation file house keeping is active
      if @max_files != nil and @max_files > 0
        retire_rotation_files(path)
      end
    end

    if @message_format
      output = event.sprintf(@message_format)
    else
      output = event.to_json
    end

    fd.write(output)
    fd.write("\n")

    flush(fd)
    close_stale_files
  end # def receive

  def teardown
    @logger.debug("Teardown: closing files")
    @files.each do |path, fd|
      begin
        fd.close
        @logger.debug("Closed file #{path}", :fd => fd)
      rescue Exception => e
        @logger.error("Excpetion while flushing and closing files.", :exception => e)
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

  # calculate the new rotation file name by searching for a free file name
  def get_rotation_file_name(path)
    return path if path == nil

    # try to find a non existing file by increasing the index
    fileIndex = 1
    newPath = "#{path}.#{fileIndex}"

    while File.exist?(newPath)
      fileIndex += 1
      newPath = "#{path}.#{fileIndex}"
    end

    return newPath
  end

  # retires rotation files.
  def retire_rotation_files(path)
    search_file_pattern = path + ".*" #roation pattern is .1,.2,....
    rotation_files = Dir[search_file_pattern]
    # now look if we have to delete some files
    if rotation_files != nil and rotation_files.count > @max_files
      #sort the file names by modification time
      rotation_files.sort_by! { |file_entry| File.mtime(file_entry) }
      # calculate how many file we have to delete
      files_to_delete_count = rotation_files.count - @max_files
      #delete the files we have to delete
      files_to_delete_count.times do |file_index|
        file_to_delete = rotation_files[file_index]
        begin
          @logger.info("Deleting file #{file_to_delete}")
          File.delete(file_to_delete)
        rescue Exception => ex
          @logger.error("Exception while deleting file. #{file_to_delete}", :exception => ex)
        end
      end
    end
  end

  def flush(fd)
    if flush_interval > 0
      flush_pending_files
    else
      fd.flush
    end
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
