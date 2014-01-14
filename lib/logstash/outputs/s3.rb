# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/plugin_mixins/aws_config"
require "zlib"

# Copy file access from file.rb
# Path string formatting
# All the S3 uploading stuff

class LogStash::Outputs::S3 < LogStash::Outputs::Base
  include LogStash::PluginMixins::AwsConfig

  config_name "s3"
  milestone 1

  # Bucket name to store logs
  config :bucket_name, :validate => :string, :required => true

  # File size limit - when the temporary file exceeds this size (in KB), transfer to S3
  config :size_limit, :validate => :number, :default => 10240

  # File time limit - sync every X seconds unless the file is empty. This overrides file size limits.
  config :time_limit, :validate => :number, :default => 3600

  # Message format, if omitted the full json will be written
  config :message_format, :validate => :string

  # Temporary path to write log files before transferring to S3
  config :tmp_log_path, :validate => :string, :default => "/tmp/logstash/" + Socket.gethostname + "-" + DateTime.now.strftime("%Y-%m-%d_%I-%M-%S") + ".log"

  # Flush interval for flushing writes to temporary files. 0 will flush on every meesage
  config :flush_interval, :validate => :number, :default => 2

  # Gzip output stream
  config :gzip, :validate => :boolean, :default => false

  public
  def aws_service_endpoint(region)
    if region == "standard"
      s3_endpoint = "s3.amazonaws.com"
    elsif region == "us-east-1"
      s3_endpoint = "s3-external-1.amazonaws.com"
    else          
      s3_endpoint = "s3-#{region}.amazonaws.com"
    end
    return {
      :s3_endpoint => s3_endpoint
    }
  end

  public
  def register
    require "aws-sdk"
    require "fileutils"

    @s3 = AWS::S3.new(aws_options_hash)

    begin
      @logger.debug("Opening S3 bucket '#{@bucket_name}"'...')
      @bucket = @s3.buckets[@bucket_name]
      if not @bucket.exists?
        @logger.error("Bucket '#{@bucket_name}' does not exist")
      end
    rescue Exception => e
        @logger.error("Unable to access S3 bucket '#{@bucket_name}': #{e.to_s}")
    end

    @logger.info("Connected to S3 bucket '#{@bucket_name}' successfully.")

    now = Time.now
    @last_flush_cycle = now
    @last_sync = now
  end

  public
  def receive(event)
    return unless output?(event)

    path = @tmp_log_path
    fd = open(path)

    if @message_format
      output = event.sprintf(@message_format)
    else
      output = event.to_json
    end

    fd.write(output)
    fd.write("\n")

    flush(fd)

    if Time.now - @last_sync > @time_limit
      @logger.info("Syncing file due to time limit")
      rotate_file
      @last_sync = Time.now
    elsif File.size(@tmp_log_path) > @size_limit
      @logger.info("Syncing file due to size limit")
      rotate_file
    end
  end

  private
  def rotate_file
    @logger.info("Would have rotated file")
  end

  public
  def teardown
    @logger.debug("Teardown: syncing files")
    file_to_s3(@tmp_log_path)
    begin
      @tmp_log_path.fd.close
      @logger.debug("Closed file #{path}", :fd => @tmp_log_path.fd)
    rescue Exception => e
      @logger.error("Exception while flushing and syncing files.", :exception => e)
    end
    finished
  end

  private
  def flush(fd)
    if flush_interval > 0
      flush_pending_file
    else
      fd.flush
    end
  end

  def flush_pending_file
    return unless Time.now - @last_flush_cycle >= flush_interval
    @logger.debug("Starting flush cycle")
    @logger.debug("Flushing file", :path => tmp_log_path, :fd => fd)
    fd.flush

    @last_flush_cycle = Time.now
  end

  def open(path)
    return @tmp_log_path[path] if @tmp_log_path.include?(path) and not @tmp_log_path[path].nil?

    @logger.info("Opening file", :path => path)

    dir = File.dirname(path)
    if !Dir.exists?(dir)
      @logger.info("Creating directory", :directory => dir)
      FileUtils.mkdir_p(dir)
    end

    stat = File.stat(path) rescue nil
    if stat and stat.ftype == "fifo" and RUBY_PLATFORM == "java"
      fd = java.io.FileWriter.new(java.io.File.new(path))
    else
      fd = File.new(path, "a")
    end
    if gzip
      fd = Zlib::GzipWriter.new(fd)
    end
    @tmp_log_path[path] = IOWriter.new(fd)
  end

  private
  def file_to_s3(filename)

  end
end

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