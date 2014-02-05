require "logstash/inputs/base"
require "logstash/namespace"

require "fog"
require "time"
require "tmpdir"
require "date"

# Stream events from files from a S3 bucket using the FOG library (instead of AWS-SDK).
# Configuration setup for the two are exactly the same.
#
# Each line from each file generates an event.
# Files ending in '.gz' are handled as gzip'ed files.
class LogStash::Inputs::S3Fog < LogStash::Inputs::Base
  config_name "s3fog"
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

  # Name of an S3 bucket to backup processed files to.
  config :backup_to_bucket, :validate => :string, :required => false
  config :backup_endpoint, :validate => ["us-east-1", "us-west-1", "us-west-2",
                                         "eu-west-1", "ap-southeast-1", "ap-southeast-2",
                                         "ap-northeast-1", "sa-east-1", "us-gov-west-1"],
                                         :required => false

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

    @region_endpoint = @region if !@region.empty?

    @region_endpoint == 'us-east-1' ? @region_endpoint = 's3.amazonaws.com' : @region_endpoint = 's3-'+@region_endpoint+'.amazonaws.com'

    @logger.info("Registering s3fog input", :bucket => @bucket, :region_endpoint => @region_endpoint)

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

    @s3fog = Fog::Storage.new(
        { :provider => 'AWS',
          :aws_access_key_id => @access_key_id,
          :aws_secret_access_key => @secret_access_key
        } )
    @last_marker_key = nil

    unless @backup_to_bucket.nil?
      @backup_bucket = @s3fog.directories.get(@backup_to_bucket)
      if @backup_bucket.nil?
        @backup_bucket = @s3fog.put_bucket(@backup_to_bucket, :location_constraint => @backup_endpoint || @region_endpoint)
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
    objects.each do |obj|
      @logger.debug('S3 input processing', :bucket => @bucket, :key => obj)
      lastmod = @s3files.body["Contents"].select { |k| k["LastModified"] == obj }.first
      process_log(queue, obj)
      sincedb_write(lastmod)
    end

  end # def process_new

  private
  def list_new(since=nil)

    if since.nil?
      since = Time.new(0)
    end

    @s3files = @s3fog.get_bucket(@bucket, :prefix => @prefix, :marker => @last_marker_key)
    is_list_complete = false
    objects = {}
    while !is_list_complete   # since AWS will only return up to 1000 results, keep going until hitting the true end of the file list.
      @s3files.body["Contents"].each do |log|
        # puts "FILE MODIFICATION STATUS: #{log["Key"]} -- #{log["LastModified"]} -- vs #{since} -- #{log["LastModified"] > since} -- #{log["LastModified"].class}"
        if log["LastModified"] > since
          objects[log["Key"]] = log["LastModified"]
        end
      end
      is_list_complete = !@s3files.body["IsTruncated"]
      unless is_list_complete
        @last_marker_key = @s3files.body["Contents"].last["Key"]
        @s3files = @s3fog.get_bucket(@bucket, :prefix => @prefix, :marker => @last_marker_key)
        @logger.debug('S3 retrieved extended file list', :prefix => @prefix, :count => @s3files.body["Contents"].size, :marker => @last_marker_key)
      end
    end

    sorted_list = objects.keys.sort {|a,b| objects[a] <=> objects[b]}
    # sorted_list.each do |k|
      # puts "Item: #{k}"
    # end
    return sorted_list

  end # def list_new

  private
  def process_log(queue, key)

    object = @s3fog.get_object(@bucket, key)
    tmp = Dir.mktmpdir('logstash-')
    begin
      filename = File.join(tmp, File.basename(key))
      if !object.body.blank?
        File.open(filename, 'wb') do |s3file|
          s3file.write(object.body)
        end
        process_local_log(queue, filename)
        unless @backup_to_bucket.nil?
          @s3fog.copy_object(@bucket, key, @backup_to_bucket, key)
        end
        unless @backup_to_dir.nil?
          FileUtils.cp(filename, @backup_to_dir)
        end
        if @delete
          @s3fog.delete_object(@bucket, key)
        end
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
          event['cloudfront_version'] = metadata[:version]
        end
        unless metadata[:format].nil?
          event['cloudfront_fields'] = metadata[:format]
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

end # class LogStash::Inputs::S3Fog
