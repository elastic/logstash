require "logstash/namespace"
require "logstash/outputs/base"
require "logstash/util/signals"

# File output.
#
# Write events to files on disk. You can use fields from the
# event as parts of the filename.
class LogStash::Outputs::File < LogStash::Outputs::Base

  config_name "file"
  
  # The path to the file to write. Event fields can be used here, 
  # like "/var/log/logstash/%{@source_host}/%{application}"
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

  public
  def register
    require "fileutils" # For mkdir_p
    @files = {}

    # Hook SIGHUP (1) to this instance
    LogStash::Util::Signals::LibC.signal(1) do |signal|
        if signal == 1
            path_list = []
            @files.each do |file_path, file_desc| 
                file_desc.flush
                file_desc.close
                path_list << file_path
            end
            @files.clear

            # now reopen everything
            path_list.each do |fpath|
                open(fpath)
            end
        end
    end

  end # def register

  public
  def receive(event)
    return unless output?(event)

    path = event.sprintf(@path)
    fd = open(path)

    # TODO(sissel): Check if we should close files not recently used.

    if @message_format
      fd.write(event.sprintf(@message_format) + "\n")
    else
      fd.write(event.to_json + "\n")
    end
    fd.flush
  end # def receive

  private
  def open(path)
    return @files[path] if @files.include?(path)

    @logger.info("Opening file", :path => path)

    dir = File.dirname(path)
    if !Dir.exists?(dir)
      @logger.info("Creating directory", :directory => dir)
      FileUtils.mkdir_p(dir) 
    end

    # work around a bug opening fifos (bug JRUBY-6280)
    stat = File.stat(path) rescue nil
    if stat and stat.ftype == "fifo" and RUBY_PLATFORM == "java"
      @files[path] = java.io.FileWriter.new(java.io.File.new(path))
    else
      @files[path] = File.new(path, "a")
    end
  end
end # class LogStash::Outputs::Gelf
