# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/plugin_mixins/aws_config"

require "time"
require "tmpdir"
require "stud/interval"

# Stream events from files from a S3 bucket.
#
# Each line from each file generates an event.
# Files ending in '.gz' are handled as gzip'ed files.
class LogStash::Inputs::S3 < LogStash::Inputs::Base
  include LogStash::PluginMixins::AwsConfig

  config_name "s3"
  milestone 1

  default :codec, "line"

  # DEPRECATED: The credentials of the AWS account used to access the bucket.
  # Credentials can be specified:
  # - As an ["id","secret"] array
  # - As a path to a file containing AWS_ACCESS_KEY_ID=... and AWS_SECRET_ACCESS_KEY=...
  # - In the environment, if not set (using variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)
  config :credentials, :validate => :array, :default => [], :deprecated => "This only exists to be backwards compatible. This plugin now uses the AwsConfig from PluginMixins"

  # The name of the S3 bucket.
  config :bucket, :validate => :string, :required => true

  # The AWS region for your bucket.
  config :region_endpoint, :validate => ["us-east-1", "us-west-1", "us-west-2",
                                "eu-west-1", "ap-southeast-1", "ap-southeast-2",
                                "ap-northeast-1", "sa-east-1", "us-gov-west-1"], :default => "us-east-1", :deprecated => "This only exists to be backwards compatible. This plugin now uses the AwsConfig from PluginMixins"

  # If specified, the prefix of filenames in the bucket must match (not a regexp)
  config :prefix, :validate => :string, :default => nil

  # Where to write the since database (keeps track of the date
  # the last handled file was added to S3). The default will write
  # sincedb files to some path matching "$HOME/.sincedb*"
  config :sincedb_path, :validate => :string, :default => ENV['HOME']

  # Name of a S3 bucket to backup processed files to.
  config :backup_to_bucket, :validate => :string, :default => nil

  # Append a prefix to the key (full path including file name in s3) after processing.
  # If backing up to another (or the same) bucket, this effectively lets you
  # choose a new 'folder' to place the files in
  config :backup_add_prefix, :validate => :string, :default => nil

  # Path of a local directory to backup processed files to.
  config :backup_to_dir, :validate => :string, :default => nil

  # Whether to delete processed files from the original bucket.
  config :delete, :validate => :boolean, :default => false

  # Interval to wait between to check the file list again after a run is finished.
  # Value is in seconds.
  config :interval, :validate => :number, :default => 60

  # Ruby style regexp of keys to exclude from the bucket
  config :exclude_pattern, :validate => :string, :default => nil


  config :since_db_backend, :validate => ["local", "s3"]

  public
  def register
    require "digest/md5"
    require "aws-sdk"

    @region = get_region

    @logger.info("Registering s3 input", :bucket => @bucket, :region => @region)

    if @sincedb_path.nil?
      @logger.error("S3 input: Configuration error, no HOME or sincedb_path set")
      raise ConfigurationError.new('No HOME or sincedb_path set')
    else
      sincedb_file = File.join(ENV["HOME"], ".sincedb_" + Digest::MD5.hexdigest("#{@bucket}+#{@prefix}"))
      @sincedb = SinceDB::File.new(sincedb_file)
    end

    s3 = get_s3object

    @s3bucket = s3.buckets[@bucket]

    unless @backup_to_bucket.nil?
      @backup_bucket = s3.buckets[@backup_to_bucket]
      unless @backup_bucket.exists?
        s3.buckets.create(@backup_to_bucket)
      end
    end

    unless @backup_to_dir.nil?
      Dir.mkdir(@backup_to_dir, 0700) unless File.exists?(@backup_to_dir)
    end
  end # def register

  def get_region
    # TODO: (ph) Deprecated, it will be removed
    if @region_endpoint && !@region_endpoint.empty? && !@region
      @region_endpoint
    else
      @region
    end
  end

  def get_s3object
    # TODO: (ph) Deprecated, it will be removed
    if @credentials.length == 1
      File.open(@credentials[0]) { |f| f.each do |line|
        unless (/^\#/.match(line))
          if(/\s*=\s*/.match(line))
            param, value = line.split('=', 2)
            param = param.chomp().strip()
            value = value.chomp().strip()
            if param.eql?('AWS_ACCESS_KEY_ID')
              @access_key_id = value
            elsif param.eql?('AWS_SECRET_ACCESS_KEY')
              @secret_access_key = value
            end
          end
        end
      end
      }
    elsif @credentials.length == 2
      @access_key_id = @credentials[0]
      @secret_access_key = @credentials[1]
    end

    if @credentials
      s3 = AWS::S3.new(
        :access_key_id => @access_key_id,
        :secret_access_key => @secret_access_key,
        :region => @region
      )
    else
      s3 = AWS::S3.new(aws_options_hash)
    end
  end

  public
  def aws_service_endpoint(region)
    return { :s3_endpoint => region }
  end

  public
  def run(queue)
    Stud.interval(@interval) do
      process_files(queue)
    end
  end # def run

  private
  def process_files(queue, since=nil)
    objects = fetch_new_files(@sincedb.read)

    objects.each do |key|
      @logger.debug("S3 input processing", :bucket => @bucket, :key => key)

      lastmod = @s3bucket.objects[key].last_modified

      process_log(queue, key)

      @sincedb.write(lastmod)
    end
  end # def process_files

  public
  def fetch_new_files(since)
    objects = {}

    @s3bucket.objects.with_prefix(@prefix).each do |log|
      @logger.debug("S3 input: Found key", :key => log.key)

      unless ignore_filename?(log.key)

        if @sincedb.newer?(log.last_modified)
          objects[log.key] = log.last_modified
          @logger.debug("S3 input: Adding to objects[]", :key => log.key)
        end
      end
    end
    return sorted_objects = objects.keys.sort {|a,b| objects[a] <=> objects[b]}
  end # def fetch_new_files

  private
  def ignore_filename?(filename)
    if (@backup_add_prefix && @backup_to_bucket == @bucket && filename =~ /^#{backup_add_prefix}/)
      return true
    elsif @exclude_pattern.nil?
      return false
    elsif filename =~ Regexp.new(@exclude_pattern)
      return true
    else
      return false
    end
  end

  private
  def process_log(queue, key)
    object = @s3bucket.objects[key]

    tmp = Dir.mktmpdir("logstash-")

    filename = File.join(tmp, File.basename(key))

    download_remote_file(object, filename)

    process_local_log(queue, filename)

    process_backup_to_bucket(object, key)
    process_backup_to_dir(filename)

    delete_file_from_bucket()
  end

  def download_remote_file(remote_object, local_filename)
    @logger.debug("S3 input: Download remove file", :remote_key => remote_object.key, :local_filename => local_filename)
    File.open(local_filename, 'wb') do |s3file|
      remote_object.read do |chunk|
        s3file.write(chunk)
      end
    end
  end

  def delete_file_from_bucket
    if @delete and @backup_to_bucket.nil?
      object.delete()
    end
  end

  public
  def process_backup_to_bucket(object, key)
    unless @backup_to_bucket.nil?
      backup_key = "#{@backup_add_prefix}#{key}"
      if @delete
        object.move_to(backup_key, :bucket => @backup_bucket)
      else
        object.copy_to(backup_key, :bucket => @backup_bucket)
      end
    end
  end

  public
  def process_backup_to_dir(filename)
    unless @backup_to_dir.nil?
      FileUtils.cp(filename, @backup_to_dir)
    end
  end

  def delete_file_from_bucket
    if @delete and @backup_to_bucket.nil?
      object.delete()
    end
  end

  private
  def process_local_log(queue, filename)
    @codec.decode(File.open(filename, 'rb')) do |event|
      decorate(event)
      queue << event
    end
  end # def process_local_log

  module SinceDB
    class File
      def initialize(file)
        @sincedb_path = file
      end

      def newer?(date)
        date > read
      end

      def read
        if ::File.exists?(@sincedb_path)
          since = Time.parse(::File.read(@sincedb_path).chomp.strip)
        else
          since = Time.new(0)
        end
        return since
      end

      def write(since = nil)
        since = Time.now() if since.nil?
        ::File.open(@sincedb_path, 'w') { |file| file.write(since.to_s) }
      end
    end
  end
end # class LogStash::Inputs::S3
