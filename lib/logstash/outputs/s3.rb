# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/plugin_mixins/aws_config"

require "socket" # for Socket.gethostname
require "thread"
require "tmpdir"
require "fileutils"

# INFORMATION:

# This plugin was created for store the logstash's events into Amazon Simple Storage Service (Amazon S3).
# For use it you needs authentications and an s3 bucket.
# Be careful to have the permission to write file on S3's bucket and run logstash with super user for establish connection.
#
# S3 plugin allows you to do something complex, let's explain:)
#
# S3 outputs create temporary files into "/opt/logstash/S3_temp/". If you want, you can change the path at the start of register method.
# This files have a special name, for example:
#
# ls.s3.ip-10-228-27-95.2013-04-18T10.00.tag_hello.part0.txt
#
# ls.s3 : indicate logstash plugin s3
#
# "ip-10-228-27-95" : indicate you ip machine, if you have more logstash and writing on the same bucket for example.
# "2013-04-18T10.00" : represents the time whenever you specify time_file.
# "tag_hello" : this indicate the event's tag, you can collect events with the same tag.
# "part0" : this means if you indicate size_file then it will generate more parts if you file.size > size_file.
#           When a file is full it will pushed on bucket and will be deleted in temporary directory.
#           If a file is empty is not pushed, but deleted.
#
# This plugin have a system to restore the previous temporary files if something crash.
#
##[Note] :
#
## If you specify size_file and time_file then it will create file for each tag (if specified), when time_file or
## their size > size_file, it will be triggered then they will be pushed on s3's bucket and will delete from local disk.
## If you don't specify size_file, but time_file then it will create only one file for each tag (if specified).
## When time_file it will be triggered then the files will be pushed on s3's bucket and delete from local disk.
#
## If you don't specify time_file, but size_file  then it will create files for each tag (if specified),
## that will be triggered when their size > size_file, then they will be pushed on s3's bucket and will delete from local disk.
#
## If you don't specific size_file and time_file you have a curios mode. It will create only one file for each tag (if specified).
## Then the file will be rest on temporary directory and don't will be pushed on bucket until we will restart logstash.
#
#
# #### Usage:
# This is an example of logstash config:
#
#    output {
#       s3{
#         access_key_id => "crazy_key"             (required)
#         secret_access_key => "monkey_access_key" (required)
#         endpoint_region => "eu-west-1"           (required)
#         bucket => "boss_please_open_your_bucket" (required)
#         size_file => 2048                        (optional)
#         time_file => 5                           (optional)
#         canned_acl => "private"                  (optional. Options are "private", "public_read", "public_read_write", "authenticated_read". Defaults to "private" )
#       }
#    }
#
class LogStash::Outputs::S3 < LogStash::Outputs::Base
  include LogStash::PluginMixins::AwsConfig

  TEMPFILE_EXTENSION = "txt"

  config_name "s3"
  milestone 1

  # S3 bucket
  config :bucket, :validate => :string

  # AWS endpoint_region
  config :endpoint_region, :validate => ["us-east-1", "us-west-1", "us-west-2",
                                         "eu-west-1", "ap-southeast-1", "ap-southeast-2",
                                        "ap-northeast-1", "sa-east-1", "us-gov-west-1"], :default => "us-east-1", :deprecated => 'Deprecated, use region instead.'

  # Set the size of file in bytes, this means that files on bucket when have dimension > file_size, they are stored in two or more file.
  # If you have tags then it will generate a specific size file for every tags
  ##NOTE: define size of file is the better thing, because generate a local temporary file on disk and then put it in bucket.
  config :size_file, :validate => :number, :default => 0

  # Set the time, in minutes, to close the current sub_time_section of bucket.
  # If you define file_size you have a number of files in consideration of the section and the current tag.
  # 0 stay all time on listerner, beware if you specific 0 and size_file 0, because you will not put the file on bucket,
  # for now the only thing this plugin can do is to put the file when logstash restart.
  config :time_file, :validate => :number, :default => 0

  ## IMPORTANT: if you use multiple instance of s3, you should specify on one of them the "restore=> true" and on the others "restore => false".
  ## This is hack for not destroy the new files after restoring the initial files.
  ## If you do not specify "restore => true" when logstash crashes or is restarted, the files are not sent into the bucket,
  ## for example if you have single Instance.
  config :restore, :validate => :boolean, :default => false

  # The S3 canned ACL to use when putting the file. Defaults to "private".
  config :canned_acl, :validate => ["private", "public_read", "public_read_write", "authenticated_read"],
         :default => "private"

  # Set the directory where logstash will store the tmp files before sending it to S3
  # default to the current OS temporary directory in linux /tmp/logstash
  config :temporary_directory, :validate => :string, :default => File.join(Dir.tmpdir(), "logstash")

  # Specify a prefix to the uploaded filename, this can simulate directories on S3
  config :prefix, :validate => :string, :default => ''

  # Specify how many workers to use to upload the files to S3
  config :upload_workers_count, :validate => :number, :default => 2


  # Exposed attributes for testing purpose.
  attr_accessor :tempfile
  attr_reader :page_counter

  def aws_s3_config
    @logger.info("Registering s3 output", :bucket => @bucket, :endpoint_region => @region)
    @s3 = AWS::S3.new(aws_options_hash)
  end

  def aws_service_endpoint(region)
    # Make the deprecated endpoint_region work
    # TODO: (ph) Remove this after deprecation.
    if @endpoint_region
      region_to_use = @endpoint_region
    else
      region_to_use = region
    end

    return {
      :s3_endpoint => region_to_use == 'us-east-1' ? 's3.amazonaws.com' : "s3-#{region_to_use}.amazonaws.com"
    }
  end

  # This method is used to manage sleep and awaken thread.
  def time_alert(interval)
    Thread.new do
      LogStash::Util::set_thread_name("<S3 periodic uploader")

      loop do
        start_time = Time.now
        yield
        elapsed = Time.now - start_time
        sleep([interval - elapsed, 0].max)
      end
    end
  end


  public
  def write_on_bucket(file)
    # find and use the bucket
    bucket = @s3.buckets[@bucket]

    remote_filename = "#{@prefix}#{File.basename(file)}"

    @logger.debug("S3: ready to write file in bucket", :remote_filename => remote_filename, :bucket => @bucket)

    begin
      # prepare for write the file
      object = bucket.objects[remote_filename]
      object.write(:file => file.path, :acl => @canned_acl)
    rescue AWS::Errors::Base => e
      raise RuntimeError.new("AWS")
    end

    @logger.debug("S3: has written remote file in bucket with canned ACL", :remote_filename => remote_filename, :bucket  => @bucket, :canned_acl => @canned_acl)
  end

  # This method is used for create new empty temporary files for use. Flag is needed for indicate new subsection time_file.
  public
  def create_temporary_file
    @tempfile.close if @tempfile && @tempfile.active
    @tempfile = File.open(get_temporary_filename(@page_counter), "a")
  end

  public
  def register
    require "aws-sdk"

    workers_not_supported

    @s3 = aws_s3_config
    @upload_queue = Queue.new

    if @prefix && @prefix =~ /[\^`><]/
      @logger.error("S3: prefix contains invalid characters", :prefix => @prefix)
      raise LogStash::ConfigurationError, "S3: prefix contains invalid characters"
    end

    if !File.directory?(@temporary_directory)
      FileUtils.mkdir_p(@temporary_directory)
    end

   configure_upload_workers()
   restore_from_crashes() if @restore == true
   reset_page_counter()
   create_temporary_file()
   configure_periodic_uploader() if time_file != 0

    @codec.on_event do |event|
      handle_event(event)
    end
  end

  public
  def configure_upload_workers
    @upload_workers = []

    @upload_workers_count.times do |worker_id|
      t = Thread.new do
        LogStash::Util::set_thread_name("<S3 upload worker")

        loop do
          file = @upload_queue.pop
          move_file_to_bucket(file) if file
        end

        sleep(0.5)
      end

      @upload_workers << t
    end

    #@upload_workers.each(&:join)
  end

  public
  def next_page
    @page_counter += 1
  end

  def reset_page_counter
    @page_counter = 0
  end

  public
  def test_s3_write
    #aws-programmatic-access-test-object with test?
  end

  public
  def restore_from_crashes
    @logger.debug("S3: is attempting to verify previous crashes...")

    Dir[File.join(@temporary_directory, "*.#{TEMPFILE_EXTENSION}")].each do |file|
      name_file = File.basename(file)
      @logger.warn("S3: have found temporary file the upload process crashed, uploading file to S3.", :filename => name_file)
      move_file_to_bucket_async(file)
    end
  end

  public
  def move_file_to_bucket(file)
    file.close

    if !File.zero?(file)
      write_on_bucket(file)
      @logger.debug("S3: file was put on the upload thread", :filename => File.basename(file), :bucket => @bucket)
    end
    File.delete(file)
  end

  def move_file_to_bucket_async(file)
    file_to_upload = file.dup
    @logger.debug("S3: Sending the file to the upload queue.", :filename => File.basename(file))
    @upload_queue.push(file.dup)
  end

  public
  def configure_periodic_uploader()
    @output_started_at = Time.now

    first_time = true
    @thread = time_alert(@time_file * 60) do
      if first_time == false
        @logger.debug("S3: time_file triggered, let's bucket the file if dosen't empty and create new file")

        move_file_to_bucket(@tempfile)
        create_temporary_file()
      else
        first_time = false
      end
    end
  end

  public
  def get_temporary_filename(page_counter = 0)
    current_time = Time.now
    filename = "ls.s3.#{Socket.gethostname}.#{current_time.strftime("%Y-%m-%dT%H.%M")}"

    if @tags.size > 0
      return File.join(@temporary_directory, "#{filename}.tag_#{@tags.join('.')}.part#{page_counter}.#{TEMPFILE_EXTENSION}")
    else
      return File.join(@temporary_directory, "#{filename}.part#{page_counter}.#{TEMPFILE_EXTENSION}")
    end
  end

  public
  def receive(event)
    return unless output?(event)
    @codec.encode(event)
  end

  def handle_event(event)
    if time_file != 0
       @logger.debug("S3: trigger files ", :minutes => (@output_started_at + 60 * time_file) - Time.now)
    end

    # if we rotate on filesize
    if write_events_to_multiple_files?
      if rotate_events_log?
        @logger.debug("S3: tempfile is too large, let's bucket it and create new file", :tempfile => File.basename(@tempfile))

        move_file_to_bucket(@tempfile)
        next_page()
        create_temporary_file()
      else
        @logger.debug("S3: tempfile file size report.", :tempfile_size => @tempfile.size, :size_file => @size_file)
      end

      write_to_tempfile(event)
      # else we put all in one file
    else
      write_to_tempfile(event)
    end
  end

  public
  def rotate_events_log?
    @tempfile.size > @size_file
  end

  public
  def write_events_to_multiple_files?
    @size_file > 0
  end

  public
  def write_to_tempfile(event)
    @logger.debug("S3: put event into tempfile ", :tempfile => File.basename(@tempfile))
    @tempfile.puts(event)
  end

  public
  #def teardown
#    @upload_workers.each(&:stop)
    #@tempfile.close
  #end
end
