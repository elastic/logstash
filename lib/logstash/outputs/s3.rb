# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/plugin_mixins/aws_config"

require "socket" # for Socket.gethostname

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
#         format => "plain"                        (optional)
#         canned_acl => "private"                  (optional. Options are "private", "public_read", "public_read_write", "authenticated_read". Defaults to "private" )
#       }
#    }
#
class LogStash::Outputs::S3 < LogStash::Outputs::Base
  include LogStash::PluginMixins::AwsConfig

  config_name "s3"
  milestone 1

  # S3 bucket
  config :bucket, :validate => :string

  # AWS endpoint_region
  config :endpoint_region, :validate => ["us-east-1", "us-west-1", "us-west-2",
                                         "eu-west-1", "ap-southeast-1", "ap-southeast-2",
                                        "ap-northeast-1", "sa-east-1", "us-gov-west-1"], :default => "us-east-1", :deprecated => 'Deprecated, use region instead.'

  # Set the size of file in KB, this means that files on bucket when have dimension > file_size, they are stored in two or more file.
  # If you have tags then it will generate a specific size file for every tags
  ##NOTE: define size of file is the better thing, because generate a local temporary file on disk and then put it in bucket.
  config :size_file, :validate => :number, :default => 0

  # Set the time, in minutes, to close the current sub_time_section of bucket.
  # If you define file_size you have a number of files in consideration of the section and the current tag.
  # 0 stay all time on listerner, beware if you specific 0 and size_file 0, because you will not put the file on bucket,
  # for now the only thing this plugin can do is to put the file when logstash restart.
  config :time_file, :validate => :number, :default => 0

  # The event format you want to store in files. Defaults to plain text.
  config :format, :validate => [ "json", "plain", "nil" ], :default => "plain"

  ## IMPORTANT: if you use multiple instance of s3, you should specify on one of them the "restore=> true" and on the others "restore => false".
  ## This is hack for not destroy the new files after restoring the initial files.
  ## If you do not specify "restore => true" when logstash crashes or is restarted, the files are not sent into the bucket,
  ## for example if you have single Instance.
  config :restore, :validate => :boolean, :default => false

  # The S3 canned ACL to use when putting the file. Defaults to "private".
  config :canned_acl, :validate => ["private", "public_read", "public_read_write", "authenticated_read"],
         :default => "private"

  # Set the directory where logstash will store the tmp files before sending it to S3
  config :temp_directory, :validate => :string, :default => "/opt/logstash/S3_temp/"

  # Specifix a prefix to the uploaded filename, this can simulate directories on S3
  config :prefix, :validate => :string, :default => ''

  # Method to set up the aws configuration and establish connection
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
      loop do
        start_time = Time.now
        yield
        elapsed = Time.now - start_time
        sleep([interval - elapsed, 0].max)
      end
    end
  end

  # this method is used for write files on bucket. It accept the file and the name of file.
  def write_on_bucket(file_data, file_basename)
    # find and use the bucket
    bucket = @s3.buckets[@bucket]

    remote_filename = "#{@prefix}#{file_basename}"

    @logger.debug "S3: ready to write "+ remote_filename +" in bucket "+@bucket+", Fire in the hole!"

    # prepare for write the file
    object = bucket.objects[remote_filename]
    object.write(:file => file_data, :acl => @canned_acl)

    @logger.debug "S3: has written "+ remote_filename +" in bucket "+@bucket + " with canned ACL \"" + @canned_acl + "\""
  end

  # This method is used for restore the previous crash of logstash or to prepare the files to send in bucket.
  # Take two parameter: flag and name. Flag indicate if you want to restore or not, name is the name of file
  def up_file(flag, pattern)
    Dir[@temp_directory+pattern].each do |file|
      name_file = File.basename(file)

      if (flag == true)
        @logger.warn "S3: have found temporary file: "+name_file+", something has crashed before... Prepare for upload in bucket!"
      end

      if (!File.zero?(file))
        write_on_bucket(file, name_file)

        if (flag == true)
          @logger.debug("S3: file restored on bucket", :filename => name_file, :bucket => @bucket)
        else
          @logger.debug("S3: file was put on bucket", :filename => name_file, :bucket => @bucket)
        end
      end

      File.delete (file)
    end
  end

  # This method is used for create new empty temporary files for use. Flag is needed for indicate new subsection time_file.
  def new_file(flag)
   if (flag == true)
     @size_counter = 0
   end

   @tempFile = File.new(get_temporary_filename(@size_counter), "w")
  end

  public
  def register
    require "aws-sdk"

    @s3 = aws_s3_config

    if @prefix && @prefix =~ /[\^`><]/
      raise LogStash::ConfigurationError, "S3: prefix contains invalid characters"
    end

    if !File.directory?(@temp_directory)
      raise LogStash::ConfigurationError, "S3: Directory #{@temp_directory} doesn't exist, create it and start logstash."
    end

   if (@restore == true )
     restore_from_crashes()
   end

   new_file(true)

   if (time_file != 0)
     configure_periodic_uploader()
   end

    @codec.on_event do |event|
      handle_event(event)
    end
  end

  public
  def restore_from_crashes
    @logger.debug("S3: is attempting to verify previous crashes...")
    up_file(true, "*.txt")
  end

  public
  def configure_periodic_uploader()
    @pass_time = Time.now

    first_time = true
    @thread = time_alert(@time_file * 60) do
      if (first_time == false)
        @logger.debug("S3: time_file triggered, let's bucket the file if dosen't empty and create new file")

        up_file(false, File.basename(@tempFile))
        new_file(true)
      else
        first_time = false
      end
    end
  end

  public
  def get_temporary_filename(size_counter = 0)
    current_time = Time.now
    current_final_path = "#{@temp_directory}ls.s3.#{Socket.gethostname}.#{current_time.strftime("%Y-%m-%dT%H.%M")}"

    if (@tags.size > 0)
      return "#{current_final_path}.tag_#{@tags.join('.')}.part#{size_counter}.txt"
    else
      return "#{current_final_path}.part#{size_counter}.txt"
    end
  end

  public
  def receive(event)
    return unless output?(event)
    @codec.encode(event)
  end

  def handle_event(event)
    if(time_file != 0)
       @logger.debug("S3: trigger files ", :minutes => (@pass_time + 60 * time_file) - Time.now)
    end

    # if specific the size
    if(write_events_to_multiple_files?)
      if (rotate_events_log?)
        @logger.debug("S3: tempfile is too large, let's bucket it and create new file", :tempfile => File.basename(@tempFile))

        up_file(false, File.basename(@tempFile))
        @size_counter += 1
        new_file(false)
      else
        @logger.debug("S3: tempfile file size report.", :tempfile_size => @tempFile.size, :size_file => @size_file)
      end

      write_to_tempfile(event)
    # else we put all in one file
    else
      write_to_tempfile(event)
    end
  end

  public
  def rotate_events_log?
    @tempFile.size >= @size_file
  end

  public
  def write_events_to_multiple_files?
    size_file != 0
  end

  public
  def write_to_tempfile(event)
    @logger.debug("S3: put event into tempfile ", :tempfile => File.basename(@tempFile))

    File.open(@tempFile, 'a') do |file|
      file.puts(event)
      file.write "\n"
    end
  end
end
# Enjoy it, by Bistic:)
