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

# The mission of DatabaseManager is to ensure the plugin running an up-to-date MaxMind database and
#   thus users are compliant with EULA.
# DatabaseManager does a daily checking by calling an endpoint to notice a version update.
# DatabaseMetadata records the update timestamp and md5 of the database in the metadata file
#   to keep track of versions and the number of days disconnects to the endpoint.
# Once a new database version release, DownloadManager downloads it, and GeoIP Filter uses it on-the-fly.
# If the last update timestamp is 25 days ago, a warning message shows in the log;
# if it was 30 days ago, the GeoIP Filter should shutdown in order to be compliant.
# There are online mode and offline mode in DatabaseManager. `online` is for automatic database update
#   while `offline` is for static database path provided by users

module LogStash module Filters module Geoip class DatabaseManager
  extend LogStash::Filters::Geoip::Util
  include LogStash::Util::Loggable
  include LogStash::Filters::Geoip::Util

  #TODO remove vendor_path
  def initialize(geoip, database_path, database_type, vendor_path)
    @geoip = geoip
    self.class.prepare_cc_db
    @mode = database_path.nil? ? :online : :offline
    @database_type = database_type
    @database_path = patch_database_path(database_path)

    if @mode == :online
      logger.info "By not manually configuring a database path with `database =>`, you accepted and agreed MaxMind EULA. "\
                  "For more details please visit https://www.maxmind.com/en/geolite2/eula"

      setup
      clean_up_database
      execute_download_job

      # check database update periodically. trigger `call` method
      @scheduler = Rufus::Scheduler.new({:max_work_threads => 1})
      @scheduler.every('24h', self)
    else
      logger.info "GeoIP database path is configured manually so the plugin will not check for update. "\
                  "Keep in mind that if you are not using the database shipped with this plugin, "\
                  "please go to https://www.maxmind.com/en/geolite2/eula and understand the terms of usage."
    end
  end

  DEFAULT_DATABASE_FILENAME = %w{
    GeoLite2-City.mmdb
    GeoLite2-ASN.mmdb
  }.map(&:freeze).freeze

  public

  # create data dir, path.data, for geoip if it doesn't exist
  # copy CC databases to data dir
  def self.prepare_cc_db
    FileUtils::mkdir_p(get_data_dir)
    unless ::File.exist?(get_file_path(CITY_DB_NAME)) && ::File.exist?(get_file_path(ASN_DB_NAME))
      cc_database_paths = ::Dir.glob(::File.join(LogStash::Environment::LOGSTASH_HOME, "vendor", "**", "{GeoLite2-ASN,GeoLite2-City}.mmdb"))
      FileUtils.cp_r(cc_database_paths, get_data_dir)
    end
  end

  def execute_download_job
    begin
      has_update, new_database_path = @download_manager.fetch_database
      @database_path = new_database_path if has_update
      @metadata.save_timestamp(@database_path)
      has_update
    rescue => e
      logger.error(e.message, error_details(e, logger))
      check_age
      false
    end
  end

  # scheduler callback
  def call(job, time)
    logger.debug "scheduler runs database update check"

    begin
      if execute_download_job
        @geoip.setup_filter(database_path)
        clean_up_database
      end
    rescue DatabaseExpiryError => e
      logger.error(e.message, error_details(e, logger))
      @geoip.expire_action
    end
  end

  def close
    @scheduler.every_jobs.each(&:unschedule) if @scheduler
  end

  def database_path
    @database_path
  end

  protected
  # return a valid database path or default database path
  def patch_database_path(database_path)
    return database_path if file_exist?(database_path)
    return database_path if database_path = get_file_path("#{DB_PREFIX}#{@database_type}.#{DB_EXT}") and file_exist?(database_path)
    raise "You must specify 'database => ...' in your geoip filter (I looked for '#{database_path}')"
  end

  def check_age
    return if @metadata.cc?

    days_without_update = (::Date.today - ::Time.at(@metadata.updated_at).to_date).to_i

    case
    when days_without_update >= 30
      raise DatabaseExpiryError, "The MaxMind database has been used for more than 30 days. Logstash is unable to get newer version from internet. "\
        "According to EULA, GeoIP plugin needs to stop in order to be compliant. "\
        "Please check the network settings and allow Logstash accesses the internet to download the latest database, "\
        "or configure a database manually (:database => PATH_TO_YOUR_DATABASE) to use a self-managed database which you can download from https://dev.maxmind.com/geoip/geoip2/geolite2/ "
    when days_without_update >= 25
      logger.warn("The MaxMind database has been used for #{days_without_update} days without update. "\
        "Logstash will fail the GeoIP plugin in #{30 - days_without_update} days. "\
        "Please check the network settings and allow Logstash accesses the internet to download the latest database ")
    else
      logger.trace("The MaxMind database hasn't updated", :days_without_update => days_without_update)
    end
  end

  # Clean up files .mmdb, .tgz which are not mentioned in metadata and not default database
  def clean_up_database
    if @metadata.exist?
      protected_filenames = (@metadata.database_filenames + DEFAULT_DATABASE_FILENAME).uniq
      existing_filenames = ::Dir.glob(get_file_path("*.{#{DB_EXT},#{GZ_EXT}}"))
                                .map { |path| ::File.basename(path) }

      (existing_filenames - protected_filenames).each do |filename|
        ::File.delete(get_file_path(filename))
        logger.debug("old database #{filename} is deleted")
      end
    end
  end

  def setup
    @metadata = DatabaseMetadata.new(@database_type)
    @metadata.save_timestamp(@database_path) unless @metadata.exist?

    @database_path = @metadata.database_path || @database_path

    @download_manager = DownloadManager.new(@database_type, @metadata)
  end

  class DatabaseExpiryError < StandardError
  end
end end end end