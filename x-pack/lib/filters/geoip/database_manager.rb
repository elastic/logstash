# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/util/loggable"
require_relative "util"
require_relative "database_metadata"
require_relative "download_manager"
require_relative "database_metric"
require "json"
require "stud/try"
require "singleton"
require "concurrent/array"
require "concurrent/timer_task"
require "thread"

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

  java_import org.apache.logging.log4j.ThreadContext

  private
  def initialize
    @triggered = false
    @trigger_lock = Mutex.new
    @download_interval = 24 * 60 * 60 # 24h
  end

  def setup
    prepare_cc_db
    cc_city_database_path = get_db_path(CITY, CC)
    cc_asn_database_path = get_db_path(ASN, CC)

    prepare_metadata
    city_database_path = @metadata.database_path(CITY)
    asn_database_path = @metadata.database_path(ASN)

    @states = { "#{CITY}" => DatabaseState.new(@metadata.is_eula(CITY),
                                               Concurrent::Array.new,
                                               city_database_path,
                                               cc_city_database_path),
                "#{ASN}" => DatabaseState.new(@metadata.is_eula(ASN),
                                              Concurrent::Array.new,
                                              asn_database_path,
                                              cc_asn_database_path) }

    @download_manager = DownloadManager.new(@metadata)

    database_metric.initialize_metrics(@metadata.get_all, @states)
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
    success_cnt = 0

    begin
      pipeline_id = ThreadContext.get("pipeline.id")
      ThreadContext.put("pipeline.id", nil)

      database_metric.set_download_status_updating

      updated_db = @download_manager.fetch_database
      updated_db.each do |database_type, valid_download, dirname, new_database_path|
        if valid_download
          @metadata.save_metadata(database_type, dirname, true)
          @states[database_type].is_eula = true
          @states[database_type].is_expired = false
          @states[database_type].database_path = new_database_path

          notify_plugins(database_type, :update, new_database_path) do |db_type, ids|
            logger.info("geoip plugin will use database #{new_database_path}",
                        :database_type => db_type, :pipeline_ids => ids) unless ids.empty?
          end

          success_cnt += 1
        end
      end

      updated_types = updated_db.map { |database_type, valid_download, dirname, new_database_path| database_type }
      (DB_TYPES - updated_types).each do |unchange_type|
        @metadata.update_timestamp(unchange_type)
        success_cnt += 1
      end
    rescue => e
      logger.error(e.message, error_details(e, logger))
    ensure
      check_age
      clean_up_database(@metadata.dirnames)
      database_metric.update_download_stats(success_cnt)

      ThreadContext.put("pipeline.id", pipeline_id)
    end
  end

  def notify_plugins(database_type, action, *args)
    plugins = @states[database_type].plugins.dup
    ids = plugins.map { |plugin| plugin.execution_context.pipeline_id }.sort
    yield database_type, ids
    plugins.each { |plugin| plugin.update_filter(action, *args) if plugin }
  end

  # call expiry action if Logstash use EULA database and fail to touch the endpoint for 30 days in a row
  def check_age(database_types = DB_TYPES)
    database_types.map do |database_type|
      next unless @states[database_type].is_eula

      metadata = @metadata.get_metadata(database_type).last
      check_at = metadata[DatabaseMetadata::Column::CHECK_AT].to_i
      days_without_update = time_diff_in_days(check_at)

      case
      when days_without_update >= 30
        was_expired = @states[database_type].is_expired
        @states[database_type].is_expired = true
        @states[database_type].database_path = nil

        notify_plugins(database_type, :expire) do |db_type, ids|
          unless was_expired
            logger.error("The MaxMind database hasn't been updated from last 30 days. Logstash is unable to get newer version from internet. "\
              "According to EULA, GeoIP plugin needs to stop using MaxMind database in order to be compliant. "\
              "Please check the network settings and allow Logstash accesses the internet to download the latest database, "\
              "or switch to offline mode (:database => PATH_TO_YOUR_DATABASE) to use a self-managed database "\
              "which you can download from https://dev.maxmind.com/geoip/geoip2/geolite2/ ")

            logger.warn("geoip plugin will stop filtering and will tag all events with the '_geoip_expired_database' tag.",
                        :database_type => db_type, :pipeline_ids => ids)
          end
        end

        database_status = DatabaseMetric::DATABASE_EXPIRED
      when days_without_update >= 25
        logger.warn("The MaxMind database hasn't been updated for last #{days_without_update} days. "\
          "Logstash will fail the GeoIP plugin in #{30 - days_without_update} days. "\
          "Please check the network settings and allow Logstash accesses the internet to download the latest database ")
        database_status = DatabaseMetric::DATABASE_TO_BE_EXPIRED
      else
        logger.trace("passed age check", :days_without_update => days_without_update)
        database_status = DatabaseMetric::DATABASE_UP_TO_DATE
      end

      database_metric.update_database_status(database_type, database_status, metadata, days_without_update)
    end
  end

  # Clean up directories which are not mentioned in the excluded_dirnames and not CC database
  def clean_up_database(excluded_dirnames = [])
    protected_dirnames = (excluded_dirnames + [CC]).uniq
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
      setup
      execute_download_job
      # check database update periodically:

      @download_task = Concurrent::TimerTask.execute(execution_interval: @download_interval) do
        LogStash::Util.set_thread_name 'geoip database download task'
        database_update_check # every 24h
      end
      @triggered = true
    end
  end

  def trigger_cc_database_fallback
    return if @triggered

    @trigger_lock.synchronize do
      return if @triggered

      logger.info "The MaxMind EULA requires users to update the GeoIP databases within 30 days following the release of the update. " \
                  "By setting `xpack.geoip.downloader.enabled` value in logstash.yml to `false`, any previously downloaded version of the database " \
                  "are destroyed and replaced by the MaxMind Creative Commons license database."

      setup_cc_database
      @triggered = true
    end
  end

  def setup_cc_database
    prepare_cc_db
    delete_eula_databases
    DatabaseMetadata.new.delete
  end

  def delete_eula_databases
    begin
      clean_up_database
    rescue => e
      details = error_details(e, logger)
      details[:databases_path] = get_data_dir_path
      logger.error "Failed to delete existing MaxMind EULA databases. To be compliant with the MaxMind EULA, you must "\
                   "manually destroy any downloaded version of the EULA databases.", details
    end
  end

  def database_auto_update?
    LogStash::SETTINGS.get("xpack.geoip.downloader.enabled")
  end

  public

  # @note this method is expected to execute on a separate thread
  def database_update_check
    logger.debug "running database update check"
    ThreadContext.put("pipeline.id", nil)
    execute_download_job
  end
  private :database_update_check

  def subscribe_database_path(database_type, database_path, geoip_plugin)
    if database_path.nil?
      if database_auto_update?
        trigger_download

        logger.info "By not manually configuring a database path with `database =>`, you accepted and agreed MaxMind EULA. "\
                    "For more details please visit https://www.maxmind.com/en/geolite2/eula" if @states[database_type].is_eula

        @states[database_type].plugins.push(geoip_plugin) unless @states[database_type].plugins.member?(geoip_plugin)
        @trigger_lock.synchronize do
          @states[database_type].database_path
        end
      else
        trigger_cc_database_fallback
        get_db_path(database_type, CC)
      end
    else
      logger.info "GeoIP database path is configured manually so the plugin will not check for update. "\
                  "Keep in mind that if you are not using the database shipped with this plugin, "\
                  "please go to https://www.maxmind.com/en/geolite2/eula and understand the terms and conditions."
      database_path
    end
  end

  def unsubscribe_database_path(database_type, geoip_plugin)
    @states[database_type].plugins.delete(geoip_plugin) if geoip_plugin && @states
  end

  def database_path(database_type)
    @states[database_type].database_path
  end

  def database_metric=(database_metric)
    @database_metric = database_metric
  end

  def database_metric
    logger.debug("DatabaseMetric is nil. No geoip metrics are available. Please report the bug") if @database_metric.nil?
    @database_metric ||= LogStash::Filters::Geoip::DatabaseMetric.new(LogStash::Instrument::NamespacedNullMetric.new)
  end

  class DatabaseState
    attr_reader :is_eula, :plugins, :database_path, :cc_database_path, :is_expired
    attr_writer :is_eula, :database_path, :is_expired

    # @param is_eula [Boolean]
    # @param plugins [Concurrent::Array]
    # @param database_path [String]
    # @param cc_database_path [String]
    def initialize(is_eula, plugins, database_path, cc_database_path)
      @is_eula = is_eula
      @plugins = plugins
      @database_path = database_path
      @cc_database_path = cc_database_path
      @is_expired = false
    end
  end
end end end end