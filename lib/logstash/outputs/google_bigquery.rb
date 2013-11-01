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

# Summary: plugin to upload log events to Google BigQuery (BQ), rolling
# files based on the date pattern provided as a configuration setting. Events
# are written to files locally and, once file is closed, this plugin uploads
# it to the configured BigQuery dataset.
#
# VERY IMPORTANT:
# 1 - To make good use of BigQuery, your log events should be parsed and
# structured. Consider using grok to parse your events into fields that can
# be uploaded to BQ.
# 2 - You must configure your plugin so it gets events with the same structure,
# so the BigQuery schema suits them. In case you want to upload log events
# with different structures, you can utilize multiple configuration blocks,
# separating different log events with Logstash conditionals. More details on
# Logstash conditionals can be found here:
# http://logstash.net/docs/1.2.1/configuration#conditionals
#
# For more info on Google BigQuery, please go to:
# https://developers.google.com/bigquery/
#
# In order to use this plugin, a Google service account must be used. For
# more information, please refer to:
# https://developers.google.com/storage/docs/authentication#service_accounts
#
# Recommendations:

# a - Experiment with the settings depending on how much log data you generate,
# your needs to see "fresh" data, and how much data you could lose in the event
# of crash. For instance, if you want to see recent data in BQ quickly, you
# could configure the plugin to upload data every minute or so (provided you
# have enough log events to justify that). Note also, that if uploads are too
# frequent, there is no guarantee that they will be imported in the same order,
# so later data may be available before earlier data.

# b - BigQuery charges for storage and for queries, depending on how much data
# it reads to perform a query. These are other aspects to consider when
# considering the date pattern which will be used to create new tables and also
# how to compose the queries when using BQ. For more info on BigQuery Pricing,
# please access:
# https://developers.google.com/bigquery/pricing
#
# USAGE:
# This is an example of logstash config:
#
# output {
#    google_bigquery {
#      project_id => "folkloric-guru-278"                        (required)
#      dataset => "logs"                                         (required)
#      csv_schema => "path:STRING,status:INTEGER,score:FLOAT"    (required)
#      key_path => "/path/to/privatekey.p12"                     (required)
#      key_password => "notasecret"                              (optional)
#      service_account => "1234@developer.gserviceaccount.com"   (required)
#      temp_directory => "/tmp/logstash-bq"                      (optional)
#      temp_file_prefix => "logstash_bq"                         (optional)
#      date_pattern => "%Y-%m-%dT%H:00"                          (optional)
#      flush_interval_secs => 2                                  (optional)
#      uploader_interval_secs => 60                              (optional)
#      deleter_interval_secs => 60                               (optional)
#    }
# }
#
# Improvements TODO list:
# - Refactor common code between Google BQ and GCS plugins.
# - Turn Google API code into a Plugin Mixin (like AwsConfig).
# - There's no recover method, so if logstash/plugin crashes, files may not
# be uploaded to BQ.
class LogStash::Outputs::GoogleBigQuery < LogStash::Outputs::Base
  config_name "google_bigquery"
  milestone 1

  # Google Cloud Project ID (number, not Project Name!).
  config :project_id, :validate => :string, :required => true

  # BigQuery dataset to which these events will be added to.
  config :dataset, :validate => :string, :required => true

  # BigQuery table ID prefix to be used when creating new tables for log data.
  # Table name will be <table_prefix>_<date>
  config :table_prefix, :validate => :string, :default => "logstash"

  # Schema for log data. It must follow this format:
  # <field1-name>:<field1-type>,<field2-name>:<field2-type>,...
  # Example: path:STRING,status:INTEGER,score:FLOAT
  config :csv_schema, :validate => :string, :required => true

  # Path to private key file for Google Service Account.
  config :key_path, :validate => :string, :required => true

  # Private key password for service account private key.
  config :key_password, :validate => :string, :default => "notasecret"

  # Service account to access Google APIs.
  config :service_account, :validate => :string, :required => true

  # Directory where temporary files are stored.
  # Defaults to /tmp/logstash-bq-<random-suffix>
  config :temp_directory, :validate => :string, :default => ""

  # Temporary local file prefix. Log file will follow the format:
  # <prefix>_hostname_date.part?.log
  config :temp_file_prefix, :validate => :string, :default => "logstash_bq"

  # Time pattern for BigQuery table, defaults to hourly tables.
  # Must Time.strftime patterns: www.ruby-doc.org/core-2.0/Time.html#method-i-strftime
  config :date_pattern, :validate => :string, :default => "%Y-%m-%dT%H:00"

  # Flush interval in seconds for flushing writes to log files. 0 will flush
  # on every message.
  config :flush_interval_secs, :validate => :number, :default => 2

  # Uploader interval when uploading new files to BigQuery. Adjust time based
  # on your time pattern (for example, for hourly files, this interval can be
  # around one hour).
  config :uploader_interval_secs, :validate => :number, :default => 60

  # Deleter interval when checking if upload jobs are done for file deletion.
  # This only affects how long files are on the hard disk after the job is done.
  config :deleter_interval_secs, :validate => :number, :default => 60

  public
  def register
    require 'csv'
    require "fileutils"
    require "thread"

    @logger.debug("BQ: register plugin")

    @fields = Array.new

    CSV.parse(@csv_schema.gsub('\"', '""')).flatten.each do |field|
      temp = field.strip.split(":")

      # Check that the field in the schema follows the format (<name>:<value>)
      if temp.length != 2
        raise "BigQuery schema must follow the format <field-name>:<field-value>"
      end

      @fields << { "name" => temp[0], "type" => temp[1] }
    end

    # Check that we have at least one field in the schema
    if @fields.length == 0
      raise "BigQuery schema must contain at least one field"
    end

    @json_schema = { "fields" => @fields }

    @upload_queue = Queue.new
    @delete_queue = Queue.new
    @last_flush_cycle = Time.now
    initialize_temp_directory()
    initialize_current_log()
    initialize_google_client()
    initialize_uploader()
    initialize_deleter()
  end

  # Method called for each log event. It writes the event to the current output
  # file, flushing depending on flush interval configuration.
  public
  def receive(event)
    return unless output?(event)

    @logger.debug("BQ: receive method called", :event => event)

    # Message must be written as json
    message = event.to_json
    # Remove "@" from property names
    message = message.gsub(/\"@(\w+)\"/, '"\1"')

    new_base_path = get_base_path()

    # Time to roll file based on the date pattern? Or are we due to upload it to BQ?
    if (@current_base_path != new_base_path || Time.now - @last_file_time >= @uploader_interval_secs)
      @logger.debug("BQ: log file will be closed and uploaded",
                    :filename => File.basename(@temp_file.to_path),
                    :size => @temp_file.size.to_s,
                    :uploader_interval_secs => @uploader_interval_secs.to_s)
      # Close alone does not guarantee that data is physically written to disk,
      # so flushing it before.
      @temp_file.fsync()
      @temp_file.close()
      initialize_next_log()
    end

    @temp_file.write(message)
    @temp_file.write("\n")

    sync_log_file()

    @logger.debug("BQ: event appended to log file",
                  :filename => File.basename(@temp_file.to_path))
  end

  public
  def teardown
    @logger.debug("BQ: teardown method called")

    @temp_file.flush()
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
      @temp_file.fsync
      return
    end

    return unless Time.now - @last_flush_cycle >= flush_interval_secs
    @temp_file.fsync
    @logger.debug("BQ: flushing file",
                  :path => @temp_file.to_path,
                  :fd => @temp_file)
    @last_flush_cycle = Time.now
  end

  ##
  # Creates temporary directory, if it does not exist.
  #
  # A random suffix is appended to the temporary directory
  def initialize_temp_directory
    if @temp_directory.empty?
      require "stud/temporary"
      @temp_directory = Stud::Temporary.directory("logstash-bq")
      @logger.info("BQ: temporary directory generated",
                   :directory => @temp_directory)
    end

    if !(File.directory? @temp_directory)
      @logger.debug("BQ: directory doesn't exist. Creating it.",
                    :directory => @temp_directory)
      FileUtils.mkdir_p(@temp_directory)
    end
  end

  ##
  # Starts thread to delete uploaded log files once their jobs are done.
  #
  # Deleter is done in a separate thread, not holding the receive method above.
  def initialize_deleter
    @uploader = Thread.new do
      @logger.debug("BQ: starting deleter")
      while true
        delete_item = @delete_queue.pop
        job_id = delete_item["job_id"]
        filename = delete_item["filename"]
        job_status = get_job_status(job_id)
        case job_status["state"]
        when "DONE"
          if job_status.has_key?("errorResult")
            @logger.error("BQ: job failed, please enable debug and check full "\
                          "response (probably the issue is an incompatible "\
                          "schema). NOT deleting local file.",
                          :job_id => job_id,
                          :filename => filename,
                          :job_status => job_status)
          else
            @logger.debug("BQ: job is done, deleting local temporary file ",
                          :job_id => job_id,
                          :filename => filename,
                          :job_status => job_status)
            File.delete(filename)
          end
        when "PENDING", "RUNNING"
          @logger.debug("BQ: job is not done, NOT deleting local file yet.",
                        :job_id => job_id,
                        :filename => filename,
                        :job_status => job_status)
          @delete_queue << delete_item
        else
          @logger.error("BQ: unknown job status, please enable debug and "\
                        "check full response (probably the issue is an "\
                        "incompatible schema). NOT deleting local file yet.",
                        :job_id => job_id,
                        :filename => filename,
                        :job_status => job_status)
        end

        sleep @deleter_interval_secs
      end
    end
  end

  ##
  # Starts thread to upload log files.
  #
  # Uploader is done in a separate thread, not holding the receive method above.
  def initialize_uploader
    @uploader = Thread.new do
      @logger.debug("BQ: starting uploader")
      while true
        filename = @upload_queue.pop

        # Reenqueue if it is still the current file.
        if filename == @temp_file.to_path
          if @current_base_path == get_base_path()
            if Time.now - @last_file_time < @uploader_interval_secs
              @logger.debug("BQ: reenqueue as log file is being currently appended to.",
                            :filename => filename)
              @upload_queue << filename
              # If we got here, it means that older files were uploaded, so let's
              # wait another minute before checking on this file again.
              sleep @uploader_interval_secs
              next
            else
              @logger.debug("BQ: flush and close file to be uploaded.",
                            :filename => filename)
              @temp_file.flush()
              @temp_file.close()
              initialize_next_log()
            end
          end
        end

        if File.size(filename) > 0
          job_id = upload_object(filename)
          @delete_queue << { "filename" => filename, "job_id" => job_id }
        else
          @logger.debug("BQ: skipping empty file.")
          @logger.debug("BQ: delete local temporary file ",
                        :filename => filename)
          File.delete(filename)
        end

        sleep @uploader_interval_secs
      end
    end
  end

  ##
  # Returns undated path used to construct base path and final full path.
  # This path only includes directory, prefix, and hostname info.
  def get_undated_path
    return @temp_directory + File::SEPARATOR + @temp_file_prefix + "_" +
      Socket.gethostname()
  end

  ##
  # Returns base path to log file that is invariant regardless of any
  # user options.
  def get_base_path
    return get_undated_path() + "_" + Time.now.strftime(@date_pattern)
  end

  ##
  # Returns full path to the log file based on global variables (like
  # current_base_path) and configuration options (max file size).
  def get_full_path
    return @current_base_path + ".part" + ("%03d" % @size_counter) + ".log"
  end

  ##
  # Returns date from a temporary log file name.
  def get_date_pattern(filename)
    match = /^#{get_undated_path()}_(?<date>.*)\.part(\d+)\.log$/.match(filename)
    return match[:date]
  end

  ##
  # Returns latest part number for a base path. This method checks all existing
  # log files in order to find the highest part number, so this file can be used
  # for appending log events.
  #
  # Only applicable if max file size is enabled.
  def get_latest_part_number(base_path)
    part_numbers = Dir.glob(base_path + ".part*.log").map do |item|
      match = /^.*\.part(?<part_num>\d+).log$/.match(item)
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
    @temp_file = IOWriter.new(fd)
    @upload_queue << @temp_file.to_path
  end

  ##
  # Opens log file on plugin initialization, trying to resume from an existing
  # file. If max file size is enabled, find the highest part number and resume
  # from it.
  def initialize_current_log
    @current_base_path = get_base_path
    @last_file_time = Time.now
    @size_counter = get_latest_part_number(@current_base_path)
    @logger.debug("BQ: resuming from latest part.",
                  :part => @size_counter)
    open_current_file()
  end

  ##
  # Generates new log file name based on configuration options and opens log
  # file. If max file size is enabled, part number if incremented in case the
  # the base log file name is the same (e.g. log file was not rolled given the
  # date pattern).
  def initialize_next_log
    new_base_path = get_base_path
    @size_counter = @current_base_path == new_base_path ? @size_counter + 1 : 0
    @logger.debug("BQ: opening next log file.",
                  :filename => @current_base_path,
                  :part => @size_counter)
    @current_base_path = new_base_path
    @last_file_time = Time.now
    open_current_file()
  end

  ##
  # Initializes Google Client instantiating client and authorizing access.
  def initialize_google_client
    require "google/api_client"
    require "openssl"

    @client = Google::APIClient.new(:application_name =>
                                    'Logstash Google BigQuery output plugin',
                                    :application_version => '0.1')
    @bq = @client.discovered_api('bigquery', 'v2')


    key = Google::APIClient::PKCS12.load_key(@key_path, @key_password)
    # Authorization scope reference:
    # https://developers.google.com/bigquery/docs/authorization
    service_account = Google::APIClient::JWTAsserter.new(@service_account,
                                                         'https://www.googleapis.com/auth/bigquery',
                                                         key)
    @client.authorization = service_account.authorize
  end

  ##
  # Uploads a local file to the configured bucket.
  def get_job_status(job_id)
    begin
      require 'json'
      @logger.debug("BQ: check job status.",
                    :job_id => job_id)
      get_result = @client.execute(:api_method => @bq.jobs.get,
                                   :parameters => {
                                     'jobId' => job_id,
                                     'projectId' => @project_id
                                   })
      response = JSON.parse(get_result.response.body)
      @logger.debug("BQ: successfully invoked API.",
                    :response => response)

      if response.has_key?("error")
        raise response["error"]
      end

      # Successful invocation
      contents = response["status"]
      return contents
    rescue => e
      @logger.error("BQ: failed to check status", :exception => e)
      # TODO(rdc): limit retries?
      sleep 1
      retry
    end
  end

  ##
  # Uploads a local file to the configured bucket.
  def upload_object(filename)
    begin
      require 'json'
      table_id = @table_prefix + "_" + get_date_pattern(filename)
      # BQ does not accept anything other than alphanumeric and _
      # Ref: https://developers.google.com/bigquery/browser-tool-quickstart?hl=en
      table_id = table_id.gsub!(':','_').gsub!('-', '_')

      @logger.debug("BQ: upload object.",
                    :filename => filename,
                    :table_id => table_id)
      media = Google::APIClient::UploadIO.new(filename, "application/octet-stream")
      body = {
        "configuration" => {
          "load" => {
            "sourceFormat" => "NEWLINE_DELIMITED_JSON",
            "schema" => @json_schema,
            "destinationTable"  =>  {
              "projectId" => @project_id,
              "datasetId" => @dataset,
              "tableId" => table_id
            },
            'createDisposition' => 'CREATE_IF_NEEDED',
            'writeDisposition' => 'WRITE_APPEND'
          }
        }
      }
      insert_result = @client.execute(:api_method => @bq.jobs.insert,
                                      :body_object => body,
                                      :parameters => {
                                        'uploadType' => 'multipart',
                                        'projectId' => @project_id
                                      },
                                      :media => media)

      job_id = JSON.parse(insert_result.response.body)["jobReference"]["jobId"]
      @logger.debug("BQ: multipart insert",
                    :job_id => job_id)
      return job_id
    rescue => e
      @logger.error("BQ: failed to upload file", :exception => e)
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
class IOWriter
  def initialize(io)
    @io = io
  end
  def write(*args)
    @io.write(*args)
  end
  def flush
    @io.flush
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
