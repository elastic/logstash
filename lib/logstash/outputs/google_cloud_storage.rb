# encoding: utf-8
# Author: Rodrigo De Castro <rdc@google.com>
# Date: 2013-09-20
#
# Copyright 2013 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require "logstash/outputs/base"
require "logstash/namespace"
require "zlib"

# Summary: plugin to upload log events to Google Cloud Storage (GCS), rolling
# files based on the date pattern provided as a configuration setting. Events
# are written to files locally and, once file is closed, this plugin uploads
# it to the configured bucket.
#
# For more info on Google Cloud Storage, please go to:
# https://cloud.google.com/products/cloud-storage
#
# In order to use this plugin, a Google service account must be used. For
# more information, please refer to:
# https://developers.google.com/storage/docs/authentication#service_accounts
#
# Recommendation: experiment with the settings depending on how much log
# data you generate, so the uploader can keep up with the generated logs.
# Using gzip output can be a good option to reduce network traffic when
# uploading the log files and in terms of storage costs as well.
#
# USAGE:
# This is an example of logstash config:
#
# output {
#    google_cloud_storage {
#      bucket => "my_bucket"                                     (required)
#      key_path => "/path/to/privatekey.p12"                     (required)
#      key_password => "notasecret"                              (optional)
#      service_account => "1234@developer.gserviceaccount.com"   (required)
#      temp_directory => "/tmp/logstash-gcs"                     (optional)
#      log_file_prefix => "logstash_gcs"                         (optional)
#      max_file_size_kbytes => 1024                              (optional)
#      output_format => "plain"                                  (optional)
#      date_pattern => "%Y-%m-%dT%H:00"                          (optional)
#      flush_interval_secs => 2                                  (optional)
#      gzip => false                                             (optional)
#      uploader_interval_secs => 60                              (optional)
#    }
# }
#
# Improvements TODO list:
# - Support logstash event variables to determine filename.
# - Turn Google API code into a Plugin Mixin (like AwsConfig).
# - There's no recover method, so if logstash/plugin crashes, files may not
# be uploaded to GCS.
# - Allow user to configure file name.
# - Allow parallel uploads for heavier loads (+ connection configuration if
# exposed by Ruby API client)
class LogStash::Outputs::GoogleCloudStorage < LogStash::Outputs::Base
  config_name "google_cloud_storage"
  milestone 1

  # GCS bucket name, without "gs://" or any other prefix.
  config :bucket, :validate => :string, :required => true

  # GCS path to private key file.
  config :key_path, :validate => :string, :required => true

  # GCS private key password.
  config :key_password, :validate => :string, :default => "notasecret"

  # GCS service account.
  config :service_account, :validate => :string, :required => true

  # Directory where temporary files are stored.
  # Defaults to /tmp/logstash-gcs-<random-suffix>
  config :temp_directory, :validate => :string, :default => ""

  # Log file prefix. Log file will follow the format:
  # <prefix>_hostname_date<.part?>.log
  config :log_file_prefix, :validate => :string, :default => "logstash_gcs"

  # Sets max file size in kbytes. 0 disable max file check.
  config :max_file_size_kbytes, :validate => :number, :default => 10000

  # The event format you want to store in files. Defaults to plain text.
  config :output_format, :validate => [ "json", "plain" ], :default => "plain"

  # Time pattern for log file, defaults to hourly files.
  # Must Time.strftime patterns: www.ruby-doc.org/core-2.0/Time.html#method-i-strftime
  config :date_pattern, :validate => :string, :default => "%Y-%m-%dT%H:00"

  # Flush interval in seconds for flushing writes to log files. 0 will flush
  # on every message.
  config :flush_interval_secs, :validate => :number, :default => 2

  # Gzip output stream when writing events to log files.
  config :gzip, :validate => :boolean, :default => false

  # Uploader interval when uploading new files to GCS. Adjust time based
  # on your time pattern (for example, for hourly files, this interval can be
  # around one hour).
  config :uploader_interval_secs, :validate => :number, :default => 60

  public
  def register
    require "fileutils"
    require "thread"

    @logger.debug("GCS: register plugin")

    @upload_queue = Queue.new
    @last_flush_cycle = Time.now
    initialize_temp_directory()
    initialize_current_log()
    initialize_google_client()
    initialize_uploader()

    if @gzip
      @content_type = 'application/gzip'
    else
      @content_type = 'text/plain'
    end
  end

  # Method called for each log event. It writes the event to the current output
  # file, flushing depending on flush interval configuration.
  public
  def receive(event)
    return unless output?(event)

    @logger.debug("GCS: receive method called", :event => event)

    if (@output_format == "json")
      message = event.to_json
    else
      message = event.to_s
    end

    new_base_path = get_base_path()

    # Time to roll file based on the date pattern? Or is it over the size limit?
    if (@current_base_path != new_base_path || (@max_file_size_kbytes > 0 && @temp_file.size >= @max_file_size_kbytes * 1024))
      @logger.debug("GCS: log file will be closed and uploaded",
                    :filename => File.basename(@temp_file.to_path),
                    :size => @temp_file.size.to_s,
                    :max_size => @max_file_size_kbytes.to_s)
      # Close does not guarantee that data is physically written to disk.
      @temp_file.fsync()
      @temp_file.close()
      initialize_next_log()
    end

    @temp_file.write(message)
    @temp_file.write("\n")

    sync_log_file()

    @logger.debug("GCS: event appended to log file",
                  :filename => File.basename(@temp_file.to_path))
  end

  public
  def teardown
    @logger.debug("GCS: teardown method called")

    @temp_file.fsync()
    @temp_file.close()
  end

  private
  ##
  # Flushes temporary log file every flush_interval_secs seconds or so.
  # This is triggered by events, but if there are no events there's no point
  # flushing files anyway.
  #
  # Inspired by lib/logstash/outputs/file.rb (flush(fd), flush_pending_files)
  def sync_log_file
    if flush_interval_secs <= 0
      @temp_file.fsync()
      return
    end

    return unless Time.now - @last_flush_cycle >= flush_interval_secs
    @temp_file.fsync()
    @logger.debug("GCS: flushing file",
                  :path => @temp_file.to_path,
                  :fd => @temp_file)
    @last_flush_cycle = Time.now
  end

  ##
  # Creates temporary directory, if it does not exist.
  #
  # A random suffix is appended to the temporary directory
  def initialize_temp_directory
    require "stud/temporary"
    if @temp_directory.empty?
      @temp_directory = Stud::Temporary.directory("logstash-gcs")
      @logger.info("GCS: temporary directory generated",
                   :directory => @temp_directory)
    end

    if !(File.directory? @temp_directory)
      @logger.debug("GCS: directory doesn't exist. Creating it.",
                    :directory => @temp_directory)
      FileUtils.mkdir_p(@temp_directory)
    end
  end

  ##
  # Starts thread to upload log files.
  #
  # Uploader is done in a separate thread, not holding the receive method above.
  def initialize_uploader
    @uploader = Thread.new do
      @logger.debug("GCS: starting uploader")
      while true
        filename = @upload_queue.pop

        # Reenqueue if it is still the current file.
        if filename == @temp_file.to_path
          if @current_base_path == get_base_path()
            @logger.debug("GCS: reenqueue as log file is being currently appended to.",
                          :filename => filename)
            @upload_queue << filename
            # If we got here, it means that older files were uploaded, so let's
            # wait another minute before checking on this file again.
            sleep @uploader_interval_secs
            next
          else
            @logger.debug("GCS: flush and close file to be uploaded.",
                          :filename => filename)
            @temp_file.fsync()
            @temp_file.close()
            initialize_next_log()
          end
        end

        upload_object(filename)
        @logger.debug("GCS: delete local temporary file ",
                      :filename => filename)
        File.delete(filename)
        sleep @uploader_interval_secs
      end
    end
  end

  ##
  # Returns base path to log file that is invariant regardless of whether
  # max file or gzip options.
  def get_base_path
    return @temp_directory + File::SEPARATOR + @log_file_prefix + "_" +
      Socket.gethostname() + "_" + Time.now.strftime(@date_pattern)
  end

  ##
  # Returns log file suffix, which will vary depending on whether gzip is
  # enabled.
  def get_suffix
    return @gzip ? ".log.gz" : ".log"
  end

  ##
  # Returns full path to the log file based on global variables (like
  # current_base_path) and configuration options (max file size and gzip
  # enabled).
  def get_full_path
    if @max_file_size_kbytes > 0
      return @current_base_path + ".part" + ("%03d" % @size_counter) + get_suffix()
    else
      return @current_base_path + get_suffix()
    end
  end

  ##
  # Returns latest part number for a base path. This method checks all existing
  # log files in order to find the highest part number, so this file can be used
  # for appending log events.
  #
  # Only applicable if max file size is enabled.
  def get_latest_part_number(base_path)
    part_numbers = Dir.glob(base_path + ".part*" + get_suffix()).map do |item|
      match = /^.*\.part(?<part_num>\d+)#{get_suffix()}$/.match(item)
      next if match.nil?
      match[:part_num].to_i
    end

    return part_numbers.max if part_numbers.any?
    0
  end

  ##
  # Opens current log file and updates @temp_file with an instance of IOWriter.
  # This method also adds file to the upload queue.
  def open_current_file()
    path = get_full_path()
    stat = File.stat(path) rescue nil
    if stat and stat.ftype == "fifo" and RUBY_PLATFORM == "java"
      fd = java.io.FileWriter.new(java.io.File.new(path))
    else
      fd = File.new(path, "a")
    end
    if @gzip
      fd = Zlib::GzipWriter.new(fd)
    end
    @temp_file = GCSIOWriter.new(fd)
    @upload_queue << @temp_file.to_path
  end

  ##
  # Opens log file on plugin initialization, trying to resume from an existing
  # file. If max file size is enabled, find the highest part number and resume
  # from it.
  def initialize_current_log
    @current_base_path = get_base_path
    if @max_file_size_kbytes > 0
      @size_counter = get_latest_part_number(@current_base_path)
      @logger.debug("GCS: resuming from latest part.",
                    :part => @size_counter)
    end
    open_current_file()
  end

  ##
  # Generates new log file name based on configuration options and opens log
  # file. If max file size is enabled, part number if incremented in case the
  # the base log file name is the same (e.g. log file was not rolled given the
  # date pattern).
  def initialize_next_log
    new_base_path = get_base_path
    if @max_file_size_kbytes > 0
      @size_counter = @current_base_path == new_base_path ? @size_counter + 1 : 0
      @logger.debug("GCS: opening next log file.",
                    :filename => @current_base_path,
                    :part => @size_counter)
    else
      @logger.debug("GCS: opening next log file.",
                    :filename => @current_base_path)
    end
    @current_base_path = new_base_path
    open_current_file()
  end

  ##
  # Initializes Google Client instantiating client and authorizing access.
  def initialize_google_client
    require "google/api_client"
    require "openssl"

    @client = Google::APIClient.new(:application_name =>
                                    'Logstash Google Cloud Storage output plugin',
                                    :application_version => '0.1')
    @storage = @client.discovered_api('storage', 'v1beta1')

    key = Google::APIClient::PKCS12.load_key(@key_path, @key_password)
    service_account = Google::APIClient::JWTAsserter.new(@service_account,
                                                         'https://www.googleapis.com/auth/devstorage.read_write',
                                                         key)
    @client.authorization = service_account.authorize
  end

  ##
  # Uploads a local file to the configured bucket.
  def upload_object(filename)
    begin
      @logger.debug("GCS: upload object.", :filename => filename)

      media = Google::APIClient::UploadIO.new(filename, @content_type)
      metadata_insert_result = @client.execute(:api_method => @storage.objects.insert,
                                               :parameters => {
                                                 'uploadType' => 'multipart',
                                                 'bucket' => @bucket,
                                                 'name' => File.basename(filename)
                                               },
                                               :body_object => {contentType: @content_type},
                                               :media => media)
      contents = metadata_insert_result.data
      @logger.debug("GCS: multipart insert",
                    :object => contents.name,
                    :self_link => contents.self_link)
    rescue => e
      @logger.error("GCS: failed to upload file", :exception => e)
      # TODO(rdc): limit retries?
      sleep 1
      retry
    end
  end
end

##
# Wrapper class that abstracts which IO being used (for instance, regular
# files or GzipWriter.
#
# Inspired by lib/logstash/outputs/file.rb.
class GCSIOWriter
  def initialize(io)
    @io = io
  end
  def write(*args)
    @io.write(*args)
  end
  def fsync
    if @io.class == Zlib::GzipWriter
      @io.flush
      @io.to_io.fsync
    else
      @io.fsync
    end
  end
  def method_missing(method_name, *args, &block)
    if @io.respond_to?(method_name)
      @io.send(method_name, *args, &block)
    else
      if @io.class == Zlib::GzipWriter && @io.to_io.respond_to?(method_name)
        @io.to_io.send(method_name, *args, &block)
      else
        super
      end
    end
  end
  attr_accessor :active
end
