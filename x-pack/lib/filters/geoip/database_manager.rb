# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/util/loggable"
require_relative "util"
require_relative "database_metadata"
require_relative "download_manager"
require "faraday"
require "json"
require "zlib"
require "stud/try"
require "down"
require "rufus/scheduler"
require "date"
require "concurrent"

# The mission of DatabaseManager is to ensure the plugin running an up-to-date MaxMind database and
#   thus users are compliant with EULA.
# DatabaseManager does a daily checking by calling an endpoint to notice a version update.
# DatabaseMetadata records the update timestamp and md5 of the database in the metadata file
#   to keep track of versions and the number of days disconnects to the endpoint.
# Once a new database version release, DownloadManager downloads it, and GeoIP Filter uses it on-the-fly.
# If the last update timestamp is 25 days ago, a warning message shows in the log;
# if it was 30 days ago, the GeoIP Filter should stop using EULA database in order to be compliant.
# There are online mode and offline mode in DatabaseManager. `online` is for automatic database update
#   while `offline` is for static database path provided by users

module LogStash module Filters module Geoip class DatabaseManager
  extend LogStash::Filters::Geoip::Util
  include LogStash::Util::Loggable
  include LogStash::Filters::Geoip::Util

  @@instance = nil
  @@instance_mutex = Mutex.new

  def initialize
    setup
    execute_download_job

    # check database update periodically. trigger `call` method
    @scheduler = Rufus::Scheduler.new({:max_work_threads => 1})
    @scheduler.every('24h', self)
  end

  private_class_method :new

  public
  def self.instance
    return @@instance if @@instance

    @@instance_mutex.synchronize do
      return @@instance if @@instance
      @@instance = new
    end

    @@instance
  end

  # scheduler callback
  def call(job, time)
    logger.debug "scheduler runs database update check"
    execute_download_job
  end

  def database_path(database_type)
    @states[database_type].database_path
  end

  def close
    @scheduler.every_jobs.each(&:unschedule) if @scheduler
  end

  def subscribe_database_path(database_type, database_path, geoip_plugin)
    if database_path.nil?
      logger.info "By using `online` mode, you accepted and agreed MaxMind EULA. "\
                  "For more details please visit https://www.maxmind.com/en/geolite2/eula" if @states[database_type].is_eula
      @states[database_type].plugins.push(geoip_plugin) unless @states[database_type].plugins.member?(geoip_plugin)
      @states[database_type].database_path
    else
      logger.info "GeoIP plugin is in offline mode. Logstash points to static database files and will not check for update. "\
                  "Keep in mind that if you are not using the database shipped with this plugin, "\
                  "please go to https://www.maxmind.com/en/geolite2/eula to accept and agree the terms and conditions."
      database_path
    end
  end

  def unsubscribe_database_path(database_type, geoip_plugin)
    @states[database_type].plugins.delete(geoip_plugin) if geoip_plugin
  end

  # create data dir, path.data, for geoip if it doesn't exist
  # copy CC databases to data dir
  def self.prepare_cc_db
    FileUtils::mkdir_p(get_data_dir)
    unless ::File.exist?(get_file_path(CITY_DB_NAME)) && ::File.exist?(get_file_path(ASN_DB_NAME))
      cc_database_paths = ::Dir.glob(::File.join(LogStash::Environment::LOGSTASH_HOME, "vendor", "**", "{GeoLite2-ASN,GeoLite2-City}.mmdb"))
      FileUtils.cp_r(cc_database_paths, get_data_dir)
    end
  end

  protected

  # initial metadata file and database states
  def setup
    self.class.prepare_cc_db

    cc_city_database_path = get_file_path(CITY_DB_NAME)
    cc_asn_database_path = get_file_path(ASN_DB_NAME)

    @metadata = DatabaseMetadata.new
    unless @metadata.exist?
      @metadata.save_metadata(CITY, cc_city_database_path, false)
      @metadata.save_metadata(ASN, cc_asn_database_path, false)
    end

    city_database_path = @metadata.database_path(CITY) || cc_city_database_path
    asn_database_path = @metadata.database_path(ASN) || cc_asn_database_path

    @states = { "#{CITY}" => DatabaseState.new(@metadata.is_eula(CITY),
                                               Concurrent::Array.new,
                                               city_database_path,
                                               cc_city_database_path),
                "#{ASN}" => DatabaseState.new(@metadata.is_eula(ASN),
                                              Concurrent::Array.new,
                                              asn_database_path,
                                              cc_asn_database_path) }

    @download_manager = DownloadManager.new(@metadata)
  end

  # update database path to the new download
  # update timestamp when download is valid or there is no update
  # do daily check and clean up
  def execute_download_job
    begin
      updated_db = @download_manager.fetch_database
      updated_db.each do |database_type, valid_download, new_database_path|
        if valid_download
          @metadata.save_metadata(database_type, new_database_path, true)
          @states[database_type].is_eula = true
          @states[database_type].database_path = new_database_path
          @states[database_type].plugins.dup.each { |plugin| plugin.setup_filter(new_database_path) if plugin }
        end
      end

      updated_type = updated_db.map { |database_type, valid_download, new_database_path| database_type }
      (DB_TYPES - updated_type).each { |unchange_type| @metadata.update_timestamp(unchange_type) }
    rescue => e
      logger.error(e.message, :cause => e.cause, :backtrace => e.backtrace)
    ensure
      check_age
      clean_up_database
    end
  end

  # terminate pipeline if database is expired and EULA
  def check_age(database_types = DB_TYPES)
    database_types.map do |database_type|
      days_without_update = (::Date.today - ::Time.at(@metadata.updated_at(database_type)).to_date).to_i

      case
      when days_without_update >= 30
        if @states[database_type].is_eula && @states[database_type].plugins.size > 0
          logger.error("The MaxMind database hasn't been updated from last 30 days. Logstash is unable to get newer version from internet. "\
            "According to EULA, GeoIP plugin needs to stop using MaxMind database in order to be compliant. "\
            "Please check the network settings and allow Logstash accesses the internet to download the latest database, "\
            "or switch to offline mode (:database => PATH_TO_YOUR_DATABASE) to use a self-managed database "\
            "which you can download from https://dev.maxmind.com/geoip/geoip2/geolite2/ ")
          @states[database_type].plugins.dup.each { |plugin| plugin.expire_action if plugin }
        end
      when days_without_update >= 25
        if @states[database_type].is_eula && @states[database_type].plugins.size > 0
          logger.warn("The MaxMind database hasn't been updated for last #{days_without_update} days. "\
          "Logstash will bypass the GeoIP plugin in #{30 - days_without_update} days. "\
          "Please check the network settings and allow Logstash accesses the internet to download the latest database ")
        end
      else
        logger.trace("The endpoint hasn't updated", :days_without_update => days_without_update)
      end
    end
  end

  # Clean up files .mmdb, .tgz which are not mentioned in metadata and not default database
  def clean_up_database
    protected_filenames = (@metadata.database_filenames + DEFAULT_DB_NAMES).uniq
    existing_filenames = ::Dir.glob(get_file_path("*.{#{DB_EXT},#{GZ_EXT}}"))
                              .map { |path| ::File.basename(path) }

    (existing_filenames - protected_filenames).each do |filename|
      ::File.delete(get_file_path(filename))
      logger.debug("old database #{filename} is deleted")
    end
  end

  class DatabaseState
    attr_reader :is_eula, :plugins, :database_path, :cc_database_path
    attr_writer :is_eula, :database_path

    # @param is_eula [Boolean]
    # @param plugins [Concurrent::Array]
    # @param database_path [String]
    # @param cc_database_path [String]
    def initialize(is_eula, plugins, database_path, cc_database_path)
      @is_eula = is_eula
      @plugins = plugins
      @database_path = database_path
      @cc_database_path = cc_database_path
    end
  end
end end end end