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
require "singleton"

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
  include Singleton

  private
  def initialize
    prepare_cc_db
    cc_city_database_path = get_db_path(CITY, CC)
    cc_asn_database_path = get_db_path(ASN, CC)

    prepare_metadata
    city_database_path = @metadata.database_path(CITY) || cc_city_database_path
    asn_database_path = @metadata.database_path(ASN) || cc_asn_database_path

    @triggered = false
    @trigger_lock = Mutex.new
    @states = { "#{CITY}" => DatabaseState.new(@metadata.is_eula(CITY),
                                               city_database_path,
                                               cc_city_database_path),
                "#{ASN}" => DatabaseState.new(@metadata.is_eula(ASN),
                                              asn_database_path,
                                              cc_asn_database_path) }

    @download_manager = DownloadManager.new(@metadata)
  end

  protected
  # create data dir, path.data, for geoip if it doesn't exist
  # copy CC databases to data dir
  def prepare_cc_db
    FileUtils::mkdir_p(get_data_dir_path)
    unless ::File.exist?(get_db_path(CITY, CC)) && ::File.exist?(get_db_path(ASN, CC))
      cc_database_paths = ::Dir.glob(::File.join(LogStash::Environment::LOGSTASH_HOME, "vendor", "**", "{GeoLite2-ASN,GeoLite2-City}.mmdb"))
      cc_dir_path = get_dir_path(CC)
      FileUtils.mkdir_p(cc_dir_path)
      FileUtils.cp_r(cc_database_paths, cc_dir_path)
    end
  end

  def prepare_metadata
    @metadata = DatabaseMetadata.new

    unless @metadata.exist?
      @metadata.save_metadata(CITY, CC, false)
      @metadata.save_metadata(ASN, CC, false)
    end

    # reset md5 to allow re-download when the database directory is deleted manually
    DB_TYPES.each { |type| @metadata.reset_md5(type) if @metadata.database_path(type).nil? }

    @metadata
  end

  # notice plugins to use the new database path
  # update metadata timestamp for those dbs that has no update or a valid update
  # do daily check and clean up
  def execute_download_job
    begin
      updated_db = @download_manager.fetch_database
      updated_db.each do |database_type, valid_download, dirname, new_database_path|
        if valid_download
          @metadata.save_metadata(database_type, dirname, true)
          @states[database_type].is_eula = true
          @states[database_type].database_path = new_database_path
          @states[database_type].observable.notify_all(:update, new_database_path)
        end
      end

      updated_type = updated_db.map { |database_type, valid_download, dirname, new_database_path| database_type }
      (DB_TYPES - updated_type).each { |unchange_type| @metadata.update_timestamp(unchange_type) }
    rescue => e
      logger.error(e.message, error_details(e, logger))
    ensure
      check_age
      clean_up_database
    end
  end

  # call expiry action if Logstash use EULA database and fail to touch the endpoint for 30 days in a row
  def check_age(database_types = DB_TYPES)
    database_types.map do |database_type|
      next if !@states[database_type].is_eula || @states[database_type].observable.count_observers == 0

      days_without_update = (::Date.today - ::Time.at(@metadata.check_at(database_type)).to_date).to_i

      case
      when days_without_update >= 30
        logger.error("The MaxMind database hasn't been updated from last 30 days. Logstash is unable to get newer version from internet. "\
          "According to EULA, GeoIP plugin needs to stop using MaxMind database in order to be compliant. "\
          "Please check the network settings and allow Logstash accesses the internet to download the latest database, "\
          "or switch to offline mode (:database => PATH_TO_YOUR_DATABASE) to use a self-managed database "\
          "which you can download from https://dev.maxmind.com/geoip/geoip2/geolite2/ ")
        @states[database_type].observable.notify_all(:expire)
      when days_without_update >= 25
        logger.warn("The MaxMind database hasn't been updated for last #{days_without_update} days. "\
          "Logstash will fail the GeoIP plugin in #{30 - days_without_update} days. "\
          "Please check the network settings and allow Logstash accesses the internet to download the latest database ")
      else
        logger.trace("The endpoint hasn't updated", :days_without_update => days_without_update)
      end
    end
  end

  # Clean up directories which are not mentioned in metadata and not CC database
  def clean_up_database
    protected_dirnames = (@metadata.dirnames + [CC]).uniq
    existing_dirnames = ::Dir.children(get_data_dir_path)
                             .select { |f| ::File.directory? ::File.join(get_data_dir_path, f) }

    (existing_dirnames - protected_dirnames).each do |dirname|
      dir_path = get_dir_path(dirname)
      FileUtils.rm_r(dir_path)
      logger.info("#{dir_path} is deleted")
    end
  end

  def trigger_download
    return if @triggered
    @trigger_lock.synchronize do
      return if @triggered
      execute_download_job
      # check database update periodically. trigger `call` method
      @scheduler = Rufus::Scheduler.new({:max_work_threads => 1})
      @scheduler.every('24h', self)
      @triggered = true
    end
  end

  public

  # scheduler callback
  def call(job, time)
    logger.debug "scheduler runs database update check"
    execute_download_job
  end

  def close
    @scheduler.shutdown if @scheduler
  end

  def subscribe_database_path(database_type, database_path, geoip_plugin)
    if database_path.nil?
      trigger_download

      logger.info "By not manually configuring a database path with `database =>`, you accepted and agreed MaxMind EULA. "\
                  "For more details please visit https://www.maxmind.com/en/geolite2/eula" if @states[database_type].is_eula

      @states[database_type].observable.add_observer(geoip_plugin, :update_filter)
      @trigger_lock.synchronize { @states[database_type].database_path }
    else
      logger.info "GeoIP database path is configured manually so the plugin will not check for update. "\
                  "Keep in mind that if you are not using the database shipped with this plugin, "\
                  "please go to https://www.maxmind.com/en/geolite2/eula and understand the terms and conditions."
      database_path
    end
  end

  def unsubscribe_database_path(database_type, geoip_plugin)
    @states[database_type].observable.delete_observer(geoip_plugin)
  end

  def database_path(database_type)
    @states[database_type].database_path
  end

  class DatabaseState
    attr_reader :is_eula, :observable, :database_path, :cc_database_path
    attr_writer :is_eula, :database_path

    # @param is_eula [Boolean]
    # @param database_path [String]
    # @param cc_database_path [String]
    def initialize(is_eula, database_path, cc_database_path)
      @is_eula = is_eula
      @observable = DatabaseObservable.new
      @database_path = database_path
      @cc_database_path = cc_database_path
    end
  end

  class DatabaseObservable
    include Observable

    def notify_all(*args)
      changed
      notify_observers(*args)
    end
  end
end end end end