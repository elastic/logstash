# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative 'constants'
require_relative 'util'
require_relative 'data_path'
require_relative 'metadata'
require_relative 'downloader'
require_relative 'subscription'
require_relative 'db_info'
require_relative 'metric'

require "logstash/util/loggable"
require "singleton"
require "concurrent/set"

##
# The GeoipDatabaseManagement's Manager can be used by plugins to acquire
# a subscription to an auto-updating, EULA-compliant Geoip database.
# The Manager is lazy by default, and begins maintaining local databases
# on disk when the first subscription is started.
#
# Once started, it queries an Elastic database service daily to discover
# available updates, loading discovered updates in the background and notifying
# all subscribers before eventually removing databases from disk that are no
# longer assigned to any subscribers.
#
# The terms of the MaxMind EULA are enforced, ensuring that databases that
# have not been synchronized with the service in more than 30 days are not
# assigned to subscribers so they can be freed. After 25 days without sync
# the manager begins emitting warning messages.
#
# The provided Metric namespace is populated with information about the
# current state of managed databases, age-since-sync, etc.
#
# @example Subscribe to a database
#   sub = Manager.instance.subscribe_database_path("City")
#   sub.observe(construct: -> (db_info) { ... },
#               on_update: -> (db_info) { ... },
#               on_expire: -> (       ) { ... })
#   sub.release! # unsubscribe
module LogStash module GeoipDatabaseManagement class Manager
  include Constants
  include Util
  include LogStash::Util::Loggable
  include Singleton

  def initialize
    @start_lock = Mutex.new

    @enabled = LogStash::SETTINGS.get("xpack.geoip.downloader.enabled")
    @endpoint = LogStash::SETTINGS.get("xpack.geoip.downloader.endpoint")
    @poll_interval = LogStash::SETTINGS.get("xpack.geoip.downloader.poll.interval")

    data_directory = ::File.expand_path("geoip_database_management", LogStash::SETTINGS.get_value('path.data'))
    @data_path = GeoipDatabaseManagement::DataPath.new(data_directory)

    @metadata = Metadata.new(data_path)

    unless enabled?
      logger.info("database manager is disabled; removing managed databases from disk``")
      metadata.delete
      clean_up_database
    end
  end

  ##
  # @param database_type [String] one of `GeoipDatabaseManagement::DB_TYPES`
  # @return [Subscription] the observer
  def subscribe_database_path(database_type)
    fail ArgumentError, "unsupported database type `#{database_type}`" unless DB_TYPES.include?(database_type)

    return nil unless enabled?

    ensure_started!

    @states.fetch(database_type).subscribe
  end

  ##
  # @return [Boolean] true unless the database management feature has been disabled
  def enabled?
    @enabled
  end

  ##
  # @return [Enumerable<String>] the types of databases that can be subscribed to
  def supported_database_types
    DB_TYPES
  end

  ##
  # @api internal
  def database_metric=(database_metric)
    @database_metric = database_metric
  end

  ##
  # @api internal
  def running?
    @start_lock.synchronize { @download_task&.running? }
  end

  protected

  attr_reader :endpoint
  attr_reader :poll_interval
  attr_reader :data_path
  attr_reader :metadata

  def database_metric
    logger.debug("Database Metric is nil. No geoip metrics are available. Please report the bug") if @database_metric.nil?
    @database_metric ||= LogStash::GeoipDatabaseManagement::Metric.new(LogStash::Instrument::NamespacedNullMetric.new)
  end

  def downloader
    @downloader ||= Downloader.new(metadata, endpoint)
  end

  def ensure_started!
    @start_lock.synchronize do
      return if @download_task

      setup
      execute_download_job

      logger.debug "spawning periodic check for updates (#{poll_interval})"
      @download_task = Concurrent::TimerTask.execute(execution_interval: poll_interval.to_seconds) do
        periodic_sync
      end
    end
  end

  def periodic_sync
    LogStash::Util::set_thread_name 'geoip database sync task' do
      LogStash::Util::with_logging_thread_context("pipeline.id" => nil) do
        logger.debug "running database update check"
        execute_download_job
      end
    end
  end

  def clean_up_database(excluded_dirnames = [])
    protected_dirnames = excluded_dirnames.uniq
    existing_dirnames = ::Dir.children(data_path.root)
                             .select { |f| ::File.directory? ::File.join(data_path.root, f) }

    (existing_dirnames - protected_dirnames).each do |dirname|
      dir_path = data_path.resolve(dirname)
      FileUtils.rm_r(dir_path)
      logger.info("Stale database directory `#{dir_path}` has been deleted")
    end
  end

  def setup
    FileUtils.mkdir_p(data_path.root)
    metadata.touch

    @states = DB_TYPES.each_with_object({}) do |type, memo|
      db_info = if metadata.has_type?(type)
                  DbInfo.new(path: metadata.database_path(type))
                else
                  DbInfo::PENDING
                end
      memo[type] = State.new(db_info)
    end

    database_metric.initialize_metrics(metadata.get_all)
  end

  def execute_download_job
    success_cnt = 0

    database_metric.set_download_status_updating

    updated_db = downloader.fetch_databases(DB_TYPES)
    updated_db.each do |database_type, valid_download, dirname, new_database_path|
      if valid_download
        metadata.save_metadata(database_type, dirname, gz_md5: md5(data_path.gz(database_type, dirname)))

        @states[database_type].update!(new_database_path) do |previous_db_info|
          logger.info("managed geoip database has been updated on disk",
                      :database_type => database_type, :database_path => new_database_path)
        end

        success_cnt += 1
      end
    end

    updated_types = updated_db.map { |database_type, valid_download, dirname, new_database_path| database_type }
    (DB_TYPES - updated_types).each do |unchange_type|
      metadata.update_timestamp(unchange_type)
      success_cnt += 1
    end
  rescue => e
    logger.error("failed to sync databases", error_details(e, logger))
  ensure
    check_age
    clean_up_database(metadata.dirnames)
    database_metric.update_download_stats(success_cnt == DB_TYPES.size)
  end

  def check_age(database_types = DB_TYPES)
    deferred_deletions = []
    database_types.map do |database_type|
      db_metadata = metadata.get_metadata(database_type).last
      if db_metadata.nil?
        logger.debug("No metadata for #{database_type}...")
        next
      end

      check_at = db_metadata[Metadata::Column::CHECK_AT].to_i
      days_without_update = time_diff_in_days(check_at)

      case
      when days_without_update >= 30
        @states[database_type].expire! do |db_info|
          logger.error("The managed MaxMind GeoIP #{database_type} database hasn't been synchronized in #{days_without_update} days "\
                       "and #{db_info.expired? ? "has been" : "will be"} removed in order to remain compliant with the MaxMind EULA. "\
                       "Logstash is unable to get newer version from internet. "\
                       "Please check the network settings and allow Logstash accesses the internet to download the latest database. "\
                       "Alternatively you can switch to a self-managed GeoIP database service (`xpack.geoip.download.endpoint`), or  "\
                       "configure each plugin with a self-managed database which you can download from https://dev.maxmind.com/geoip/geoip2/geolite2/ ")
        end

        deferred_deletions << metadata.database_path(database_type)
        metadata.unset_path(database_type)

        database_status = Metric::DATABASE_EXPIRED
      when days_without_update >= 25
        logger.warn("The MaxMind GeoIP #{database_type} database hasn't been synchronized in #{days_without_update} days. "\
                    "Logstash will remove access to the stale database in #{30 - days_without_update} days in order to remain compliant with the MaxMind EULA. "\
                    "Please check the network settings and allow Logstash accesses the internet to download the latest database.")
        database_status = Metric::DATABASE_TO_BE_EXPIRED
      else
        logger.trace("The MaxMind GeoIP #{database_type} database passed age check", :days_without_update => days_without_update)
        database_status = Metric::DATABASE_UP_TO_DATE
      end

      database_metric.update_database_status(database_type, database_status, db_metadata, days_without_update)
    end
  ensure
    deferred_deletions.compact.each do |path|
      FileUtils.rm(path, force: true)
      logger.debug("Removed database file `#{path}`")
    end
  end

  ##
  # @api testing
  def shutdown!
    @start_lock.synchronize do
      return unless @download_task&.running?

      @download_task.shutdown
      10.times do
        break unless @download_task.running?
        sleep 1
      end

      @states.values.each(&:delete_observers)
    end
  end
  private :shutdown!

  ##
  # @api testing
  def current_db_info(database_type)
    current_state(database_type)&.db_info
  end
  private :current_db_info

  ##
  # @api testing
  def current_state(database_type)
    @states&.dig(database_type)
  end
  private :current_state

  ##
  # @api private
  class State
    attr_reader :db_info

    require 'observer' # ruby stdlib
    include Observable

    def initialize(db_info)
      @db_info = db_info
    end

    ##
    # @api internal
    def subscribe
      synchronize do
        subscription = Subscription.new(@db_info, self)
        add_observer(subscription, :notify)
        subscription
      end
    end

    def unsubscribe(observer)
      synchronize do
        delete_observer(observer)
      end
    end

    ##
    # @param new_database_path [String]
    # @yieldparam previous_db_info [DbInfo]
    # @yieldreturn [void]
    def update!(new_database_path)
      synchronize do
        previous_db_info, @db_info = @db_info, DbInfo.new(path: new_database_path)

        changed

        yield(previous_db_info) if block_given?

        notify_observers(@db_info)
      end
    end

    ##
    # @yieldparam previous_path [String]
    # @yieldparam was_expired [Boolean]
    # @yieldreturn [void]
    def expire!
      synchronize do
        previous_db_info, @db_info = @db_info, DbInfo::EXPIRED

        changed

        yield(previous_db_info) if block_given?

        notify_observers(@db_info)
      end
    end

    ##
    # @api internal
    def release!(subscription)
      synchronize do
        delete_observer(subscription)
      end
    end

    private

    def synchronize(&block)
      LogStash::Util.synchronize(self) do
        yield
      end
    end

  end

end; end; end
