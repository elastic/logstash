# encoding: utf-8

# TODO integrate aws_config in the future
# require "logstash/plugin_mixins/aws_config"
require "logstash/outputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# This plugin was created to store logstash events into Amazon Simple
# Storage Service (Amazon S3). To use it, you need an AWS account with credentials to write to an S3 bucket.
#
# Output details:
#
# This output creates temporary files into `/opt/logstash/S3_temp/`. These files have a special name, for example:
#     ls.s3.ip-10-228-27-95.2013-04-18T10.00.tag_hello.part0.txt
#
# * `ls.s3`: Prefix indicating Logstash S3 plugin.
# * `ip-10-228-27-95`: The IP of the logstash machine. If you have multiple machines running logstash, this can help you distinguish which host sent the event.
# `2013-04-18T10.00`: Time the file was created, for use with time_file.
# `tag_hello`: Tag of the events contained in the file.
# `part0`: The part of the file when `size_file` is used to split files based on size. When a temporary file reaches size of `size_file` it will pushed into the bucket and deleted from the temporary directory. Files empty at `time_file` interval are deleted.
#
# This plugin has a system to restore the previous temporary files if something crashes.
#
# `time_file` and `size_file` behavior:
#
# If you specify `size_file` and `time_file` then it will create `.partN` files for each tag (if
# specified). When `time_file` is reached or their size > `size_file`, a new file will be created, and the existing files
# will be uploaded to s3 and then deleted from disk.
#
# If you specify only `time_file` then it will create a file for each tag
# (if specified). When `time_file` is reached, a new file will be created, and the existing files
# will be uploaded to s3 and then deleted from disk.
#
# If you specify only `size_file` then it will create `.partN` files for each tag (if specified).
# When their size > `size_file`, a new file will be created, and the existing files
# will be uploaded to s3 and then deleted from disk.
#
# If you don't specify `size_file` or `time_file` you have a curious mode. It will create a file for each tag (if
# specified). Then the file will stay in the temporary directory without being uploaded to s3 until logstash is restarted.
#
# Improvements welcome:
#  * Integrate aws_config in the future
#  * Find a method to upload all files when logtstash closes the session.
#  * Integrate @field on the path file
#  * Permanent connection or on demand? For now on demand, but isn't a good implementation.
#  * Use a while or a thread to try the connection before break a time_out and signal an error.
#
#  If you have bugs report or helpful advice contact me, but remember that this
#  code is much mine as much as yours, try to work on it if you want :)
#
# USAGE:
#
# This is an example of logstash config:
#
#     output {
#        s3{
#          access_key_id => "crazy_key"             (required)
#          secret_access_key => "monkey_access_key" (required)
#          endpoint_region => "eu-west-1"           (required)
#          bucket => "boss_please_open_your_bucket" (required)
#          size_file => 2048                        (optional)
#          time_file => 5                           (optional)
#          format => "plain"                        (optional)
#          canned_acl => "private"                  (optional. Options are "private", "public_read", "public_read_write", "authenticated_read". Defaults to "private" )
#        }
#     }
#
# access_key_id => "crazy_key"
# Amazon will give you the key for use their service if you buy it or try it. (not very much open source anyway)
# secret_access_key => "monkey_access_key"
# Amazon will give you the secret_access_key for use their service if you buy it or try it . (not very much open source anyway).
# endpoint_region => "eu-west-1"
# When you make a contract with Amazon, you should know where the services you use.
# bucket => "boss_please_open_your_bucket"
# Be careful you have the permission to write on bucket and know the name.
# size_file => 2048
# Means the size, in KB, of files who can store on temporary directory before you will be pushed on bucket.
# Is useful if you have a little server with poor space on disk and you don't want blow up the server with unnecessary temporary log files.
# time_file => 5
# Means, in minutes, the time  before the files will be pushed on bucket. Is useful if you want to push the files every specific time.
# format => "plain"
# Means the format of events you want to store in the files
# canned_acl => "private"
# The S3 canned ACL to use when putting the file. Defaults to "private".

class LogStash::Outputs::S3 < LogStash::Outputs::Base
  # TODO integrate aws_config in the future
  # include LogStash::PluginMixins::AwsConfig

 config_name "s3"
 milestone 1

 # AWS access_key_id
 config :access_key_id, :validate => :string

 # AWS secret_access_key
 config :secret_access_key, :validate => :string

 # S3 bucket to place files into.
 config :bucket, :validate => :string

 # S3 region to use.
 config :endpoint_region, :validate => ["us-east-1", "us-west-1", "us-west-2",
                                        "eu-west-1", "ap-southeast-1", "ap-southeast-2",
                                        "ap-northeast-1", "sa-east-1", "us-gov-west-1"], :default => "us-east-1"

 # Set the size of file parts in KB. This means that when each file grows to this size, a new .part is created for upload. If you have tags then it will generate a specific size file for every tag.
 # This is an optional field but setting is recommended.
 config :size_file, :validate => :number, :default => 0

 # Set the time, in minutes, to upload each log file part. If you wanted to upload a new file every day, for example, set this to 1440.
 # If you also set `size_file`, you may also have a group of .part files that are uploaded.
 # Avoid setting both this and `size_file` to 0, because you will not upload anything to s3 until logstash is restarted.
 config :time_file, :validate => :number, :default => 0

 # The event format you want to store in files. Defaults to plain text.
 config :format, :validate => [ "json", "plain", "nil" ], :default => "plain"

 # Whether to upload files on disk into the s3 bucket when logstash is restarted.
 # IMPORTANT: if you use multiple instances of this output, only one of them should have this value set to true. This is why it defaults to false.
 config :restore, :validate => :boolean, :default => false

 # S3 canned_acl for new files.
 config :canned_acl, :validate => ["private", "public_read", "public_read_write", "authenticated_read"],
        :default => "private"

 # Method to set up the aws configuration and establish connection
 def aws_s3_config

  @endpoint_region == 'us-east-1' ? @endpoint_region = 's3.amazonaws.com' : @endpoint_region = 's3-'+@endpoint_region+'.amazonaws.com'

  @logger.info("Registering s3 output", :bucket => @bucket, :endpoint_region => @endpoint_region)

  AWS.config(
    :access_key_id => @access_key_id,
    :secret_access_key => @secret_access_key,
    :s3_endpoint => @endpoint_region
  )
  @s3 = AWS::S3.new

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
 def write_on_bucket (file_data, file_basename)

  # if you lose connection with s3, bad control implementation.
  if ( @s3 == nil)
    aws_s3_config
  end

  # find and use the bucket
  bucket = @s3.buckets[@bucket]

  @logger.debug "S3: ready to write "+file_basename+" in bucket "+@bucket+", Fire in the hole!"

  # prepare for write the file
  object = bucket.objects[file_basename]
  object.write(:file => file_data, :acl => @canned_acl)

  @logger.debug "S3: has written "+file_basename+" in bucket "+@bucket + " with canned ACL \"" + @canned_acl + "\""

 end

 # this method is used for create new path for name the file
 def getFinalPath

   @pass_time = Time.now
   return @temp_directory+"ls.s3."+Socket.gethostname+"."+(@pass_time).strftime("%Y-%m-%dT%H.%M")

 end

 # This method is used for restore the previous crash of logstash or to prepare the files to send in bucket.
 # Take two parameter: flag and name. Flag indicate if you want to restore or not, name is the name of file
 def upFile(flag, name)

   Dir[@temp_directory+name].each do |file|
     name_file = File.basename(file)

     if (flag == true)
      @logger.warn "S3: have found temporary file: "+name_file+", something has crashed before... Prepare for upload in bucket!"
     end

     if (!File.zero?(file))
       write_on_bucket(file, name_file)

       if (flag == true)
          @logger.debug "S3: file: "+name_file+" restored on bucket "+@bucket
       else
          @logger.debug "S3: file: "+name_file+" was put on bucket "+@bucket
       end
     end

     File.delete (file)

   end
 end

 # This method is used for create new empty temporary files for use. Flag is needed for indicate new subsection time_file.
 def newFile (flag)

   if (flag == true)
     @current_final_path = getFinalPath
     @sizeCounter = 0
   end

   if (@tags.size != 0)
     @tempFile = File.new(@current_final_path+".tag_"+@tag_path+"part"+@sizeCounter.to_s+".txt", "w")
   else
     @tempFile = File.new(@current_final_path+".part"+@sizeCounter.to_s+".txt", "w")
   end

 end

 public
 def register
   require "aws-sdk"
   @temp_directory = "/opt/logstash/S3_temp/"

   if (@tags.size != 0)
       @tag_path = ""
       for i in (0..@tags.size-1)
          @tag_path += @tags[i].to_s+"."
       end
   end

   if !(File.directory? @temp_directory)
    @logger.debug "S3: Directory "+@temp_directory+" doesn't exist, let's make it!"
    Dir.mkdir(@temp_directory)
   else
    @logger.debug "S3: Directory "+@temp_directory+" exist, nothing to do"
   end

   if (@restore == true )
     @logger.debug "S3: is attempting to verify previous crashes..."

     upFile(true, "*.txt")
   end

   newFile(true)

   if (time_file != 0)
      first_time = true
      @thread = time_alert(@time_file*60) do
       if (first_time == false)
         @logger.debug "S3: time_file triggered,  let's bucket the file if dosen't empty  and create new file "
         upFile(false, File.basename(@tempFile))
         newFile(true)
       else
         first_time = false
       end
     end
   end

 end

 public
 def receive(event)
  return unless output?(event)

  # Prepare format of Events
  if (@format == "plain")
     message = self.class.format_message(event)
  elsif (@format == "json")
     message = event.to_json
  else
     message = event.to_s
  end

  if(time_file !=0)
     @logger.debug "S3: trigger files after "+((@pass_time+60*time_file)-Time.now).to_s
  end

  # if specific the size
  if(size_file !=0)

    if (@tempFile.size < @size_file )

       @logger.debug "S3: File have size: "+@tempFile.size.to_s+" and size_file is: "+ @size_file.to_s
       @logger.debug "S3: put event into: "+File.basename(@tempFile)

       # Put the event in the file, now!
       File.open(@tempFile, 'a') do |file|
         file.puts message
         file.write "\n"
       end

     else

       @logger.debug "S3: file: "+File.basename(@tempFile)+" is too large, let's bucket it and create new file"
       upFile(false, File.basename(@tempFile))
       @sizeCounter += 1
       newFile(false)

     end

  # else we put all in one file
  else

    @logger.debug "S3: put event into "+File.basename(@tempFile)
    File.open(@tempFile, 'a') do |file|
      file.puts message
      file.write "\n"
    end
  end

 end

 def self.format_message(event)
    message = "Date: #{event[LogStash::Event::TIMESTAMP]}\n"
    message << "Source: #{event["source"]}\n"
    message << "Tags: #{event["tags"].join(', ')}\n"
    message << "Fields: #{event.to_hash.inspect}\n"
    message << "Message: #{event["message"]}"
 end

end

# Enjoy it, by Bistic:)
