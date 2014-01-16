# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"

require "time"
require "tmpdir"

# Stream events from files from a S3 bucket.
#
# Each line from each file generates an event.
# Files ending in '.gz' are handled as gzip'ed files.
class LogStash::Inputs::S3 < LogStash::Inputs::Base
  config_name "s3"
  milestone 1

  # TODO(sissel): refactor to use 'line' codec (requires removing both gzip
  # support and readline usage). Support gzip through a gzip codec! ;)
  default :codec, "plain"

  # The credentials of the AWS account used to access the bucket.
  # Credentials can be specified:
  # - As an ["id","secret"] array
  # - As a path to a file containing AWS_ACCESS_KEY_ID=... and AWS_SECRET_ACCESS_KEY=...
  # - In the environment (variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)
  config :credentials, :validate => :array, :default => nil

  # The name of the S3 bucket.
  config :bucket, :validate => :string, :required => true

  # The AWS region for your bucket.
  config :region, :validate => ["us-east-1", "us-west-1", "us-west-2",
                                "eu-west-1", "ap-southeast-1", "ap-southeast-2",
                                "ap-northeast-1", "sa-east-1", "us-gov-west-1"],
                                :deprecated => "'region' has been deprecated in favor of 'region_endpoint'"

  # The AWS region for your bucket.
  config :region_endpoint, :validate => ["us-east-1", "us-west-1", "us-west-2",
                                "eu-west-1", "ap-southeast-1", "ap-southeast-2",
                                "ap-northeast-1", "sa-east-1", "us-gov-west-1"], :default => "us-east-1"

  # If specified, the prefix the filenames in the bucket must match (not a regexp)
  config :prefix, :validate => :string, :default => nil

  # Where to write the since database (keeps track of the date
  # the last handled file was added to S3). The default will write
  # sincedb files to some path matching "$HOME/.sincedb*"
  config :sincedb_path, :validate => :string, :default => nil

  # Name of a S3 bucket to backup processed files to.
  config :backup_to_bucket, :validate => :string, :default => nil

  # Path of a local directory to backup processed files to.
  config :backup_to_dir, :validate => :string, :default => nil

  # Whether to delete processed files from the original bucket.
  config :delete, :validate => :boolean, :default => false

  # Interval to wait between to check the file list again after a run is finished.
  # Value is in seconds.
  config :interval, :validate => :number, :default => 60

  public
  def register
    require "digest/md5"
    require "aws-sdk"

    @region_endpoint = @region if @region && !@region.empty?

    @logger.info("Registering s3 input", :bucket => @bucket, :region_endpoint => @region_endpoint)

    if @credentials.nil?
      @access_key_id = ENV['AWS_ACCESS_KEY_ID']
      @secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    elsif @credentials.is_a? Array
      if @credentials.length ==1
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
      else
        raise ArgumentError.new('Credentials must be of the form "/path/to/file" or ["id", "secret"]')
      end
    end
    if @access_key_id.nil? or @secret_access_key.nil?
      raise ArgumentError.new('Missing AWS credentials')
    end

    if @bucket.nil?
      raise ArgumentError.new('Missing AWS bucket')
    end

    if @sincedb_path.nil?
      if ENV['HOME'].nil?
        raise ArgumentError.new('No HOME or sincedb_path set')
      end
      @sincedb_path = File.join(ENV["HOME"], ".sincedb_" + Digest::MD5.hexdigest("#{@bucket}+#{@prefix}"))
    end

    s3 = AWS::S3.new(
      :access_key_id => @access_key_id,
      :secret_access_key => @secret_access_key,
      :region => @region_endpoint
    )

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

  public
  def run(queue)
    loop do
      process_new(queue)
      sleep(@interval)
    end
    finished
  end # def run

  private
  def process_new(queue, since=nil)

    if since.nil?
        since = sincedb_read()
    end

    objects = list_new(since)
    objects.each do |k|
      @logger.debug("S3 input processing", :bucket => @bucket, :key => k)
      lastmod = @s3bucket.objects[k].last_modified
      process_log(queue, k)
      sincedb_write(lastmod)
    end

  end # def process_new

  private
  def list_new(since=nil)

    if since.nil?
      since = Time.new(0)
    end

    objects = {}
    @s3bucket.objects.with_prefix(@prefix).each do |log|
      if log.last_modified > since
        objects[log.key] = log.last_modified
      end
    end

    return sorted_objects = objects.keys.sort {|a,b| objects[a] <=> objects[b]}

  end # def list_new

  private
  def process_log(queue, key)

    object = @s3bucket.objects[key]
    tmp = Dir.mktmpdir("logstash-")
    begin
      filename = File.join(tmp, File.basename(key))
      File.open(filename, 'wb') do |s3file|
        object.read do |chunk|
          s3file.write(chunk)
        end
      end
      process_local_log(queue, filename)
      unless @backup_to_bucket.nil?
        backup_object = @backup_bucket.objects[key]
        backup_object.write(Pathname.new(filename))
      end
      unless @backup_to_dir.nil?
        FileUtils.cp(filename, @backup_to_dir)
      end
      if @delete
        object.delete()
      end
    end
    FileUtils.remove_entry_secure(tmp, force=true)

  end # def process_log

  private
  def process_local_log(queue, filename)

    metadata = {
      :version => nil,
      :format => nil,
    }
    File.open(filename) do |file|
      if filename.end_with?('.gz')
        gz = Zlib::GzipReader.new(file)
        gz.each_line do |line|
          metadata = process_line(queue, metadata, line)
        end
      else
        file.each do |line|
          metadata = process_line(queue, metadata, line)
        end
      end
    end

  end # def process_local_log

  private
  def process_line(queue, metadata, line)

    if /#Version: .+/.match(line)
      junk, version = line.strip().split(/#Version: (.+)/)
      unless version.nil?
        metadata[:version] = version
      end
    elsif /#Fields: .+/.match(line)
      junk, format = line.strip().split(/#Fields: (.+)/)
      unless format.nil?
        metadata[:format] = format
      end
    else
      @codec.decode(line) do |event|
        decorate(event)
        unless metadata[:version].nil?
          event["cloudfront_version"] = metadata[:version]
        end
        unless metadata[:format].nil?
          event["cloudfront_fields"] = metadata[:format]
        end
        queue << event
      end
    end
    return metadata

  end # def process_line

  private
  def sincedb_read()

    if File.exists?(@sincedb_path)
      since = Time.parse(File.read(@sincedb_path).chomp.strip)
    else
      since = Time.new(0)
    end
    return since

  end # def sincedb_read

  private
  def sincedb_write(since=nil)

    if since.nil?
      since = Time.now()
    end
    File.open(@sincedb_path, 'w') { |file| file.write(since.to_s) }

  end # def sincedb_write

end # class LogStash::Inputs::S3
