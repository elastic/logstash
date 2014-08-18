# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# TODO integrate aws_config in the future
#require "logstash/plugin_mixins/aws_config"

# INFORMATION:

# This plugin was created for store the logstash's events into Amazon Simple Storage Service (Amazon S3).
# For use it you needs authentications and an s3 bucket.
# Be careful to have the permission to write file on S3's bucket and run logstash with super user for establish connection.

# S3 plugin allows you to do something complex, let's explain:)

# S3 outputs create temporary files into "/opt/logstash/S3_temp/". If you want, you can change the path at the start of register method.
# This files have a special name, for example:

# ls.s3.ip-10-228-27-95.2013-04-18T10.00.tag_hello.part0.txt

# ls.s3 : indicate logstash plugin s3

# "ip-10-228-27-95" : indicate you ip machine, if you have more logstash and writing on the same bucket for example.
# "2013-04-18T10.00" : represents the time whenever you specify time_file.
# "tag_hello" : this indicate the event's tag, you can collect events with the same tag.
# "part0" : this means if you indicate size_file then it will generate more parts if you file.size > size_file.
#           When a file is full it will pushed on bucket and will be deleted in temporary directory.
#           If a file is empty is not pushed, but deleted.

# This plugin have a system to restore the previous temporary files if something crash.

##[Note] :

## If you specify size_file and time_file then it will create file for each tag (if specified), when time_file or
## their size > size_file, it will be triggered then they will be pushed on s3's bucket and will delete from local disk.

## If you don't specify size_file, but time_file then it will create only one file for each tag (if specified).
## When time_file it will be triggered then the files will be pushed on s3's bucket and delete from local disk.

## If you don't specify time_file, but size_file  then it will create files for each tag (if specified),
## that will be triggered when their size > size_file, then they will be pushed on s3's bucket and will delete from local disk.

## If you don't specific size_file and time_file you have a curios mode. It will create only one file for each tag (if specified).
## Then the file will be rest on temporary directory and don't will be pushed on bucket until we will restart logstash.

# INFORMATION ABOUT CLASS:

# I tried to comment the class at best i could do.
# I think there are much thing to improve, but if you want some points to develop here a list:

# TODO Integrate aws_config in the future
# TODO Find a method to push them all files when logtstash close the session.
# TODO Integrate @field on the path file
# TODO Permanent connection or on demand? For now on demand, but isn't a good implementation.
#      Use a while or a thread to try the connection before break a time_out and signal an error.
# TODO If you have bugs report or helpful advice contact me, but remember that this code is much mine as much as yours,
#      try to work on it if you want :)


# USAGE:

# This is an example of logstash config:

# output {
#    s3{
#      access_key_id => "crazy_key"             (required)
#      secret_access_key => "monkey_access_key" (required)
#      endpoint_region => "eu-west-1"           (required)
#      bucket => "boss_please_open_your_bucket" (required)
#      size_file => 2048                        (optional)
#      time_file => 5                           (optional)
#      format => "plain"                        (optional)
#      canned_acl => "private"                  (optional. Options are "private", "public_read", "public_read_write", "authenticated_read". Defaults to "private" )
#    }
# }

# We analize this:

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

# LET'S ROCK AND ROLL ON THE CODE!

class LogStash::Outputs::S3 < LogStash::Outputs::Base
 #TODO integrate aws_config in the future
 #  include LogStash::PluginMixins::AwsConfig

 config_name "s3"
 milestone 1

 # Aws access_key.
 config :access_key_id, :validate => :string

 # Aws secret_access_key
 config :secret_access_key, :validate => :string

 # S3 bucket
 config :bucket, :validate => :string

 # Aws endpoint_region
 config :endpoint_region, :validate => ["us-east-1", "us-west-1", "us-west-2",
                                        "eu-west-1", "ap-southeast-1", "ap-southeast-2",
                                        "ap-northeast-1", "sa-east-1", "us-gov-west-1"], :default => "us-east-1"

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

 # Aws canned ACL
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
