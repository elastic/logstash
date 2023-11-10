# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/util/loggable"
require "json"
require "stud/try"
require "singleton"
require "concurrent/array"
require "concurrent/timer_task"
require "thread"

require "geoip_database_management/manager"

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
  include LogStash::Util::Loggable
  include Singleton

  CC_DB_TYPES = %w(City ASN).map(&:freeze).freeze

  java_import org.apache.logging.log4j.ThreadContext

  private
  def initialize
    @triggered = false
    @trigger_lock = Monitor.new

    @data_dir_path = ::File.join(LogStash::SETTINGS.get_value("path.data"), "plugins", "filters", "geoip")
  end

  def eula_manager
    @eula_manager ||= LogStash::GeoipDatabaseManagement::Manager.instance
  end

  def setup
    @eula_subscriptions = eula_manager.supported_database_types.each_with_object({}) do |database_type, memo|
      memo[database_type] = eula_manager.subscribe_database_path(database_type).observe(
        construct: -> (initial_db_info) { create!(database_type, initial_db_info) },
        on_update: -> (updated_db_info) { update!(database_type, updated_db_info) },
        on_expire: -> (               ) { expire!(database_type) }
      )
    end
  end

  def trigger_download
    return if @triggered
    @trigger_lock.synchronize do
      setup if @eula_subscriptions.nil?
      @triggered = true
    end
  end

  protected
  # resolve vendored databases...
  def prepare_cc_db
    geoip_filter_plugin_path = Gem.loaded_specs['logstash-filter-geoip']&.full_gem_path or fail("geoip filter plugin library not found")
    vendored_cc_licensed_dbs = ::File.expand_path('vendor', geoip_filter_plugin_path)

    @cc_dbs = CC_DB_TYPES.each_with_object({}) do |database_type, memo|
      database_filename = "GeoLite2-#{database_type}.mmdb"
      vendored_database_path = ::File.expand_path(database_filename, vendored_cc_licensed_dbs)
      fail("vendored #{database_type} database not present in #{vendored_cc_licensed_dbs}") unless ::File::exists?(vendored_database_path)

      cc_dir_path = ::File.expand_path("CC", @data_dir_path)
      FileUtils.mkdir_p(cc_dir_path)
      FileUtils.cp_r(vendored_database_path, cc_dir_path)

      memo[database_type] = ::File.expand_path(database_filename, cc_dir_path)
    end
    logger.info("CC-licensed GeoIP databases are prepared for use by the GeoIP filter: #{@cc_dbs}")
  rescue => e
    fail "CC-licensed GeoIP databases could not be loaded: #{e}"
  end

  def notify_plugins(database_type, action, *args)
    plugins = @states[database_type].plugins.dup
    ids = plugins.map { |plugin| plugin.execution_context.pipeline_id }.sort.uniq
    yield database_type, ids
    plugins.each { |plugin| plugin.update_filter(action, *args) if plugin }
  end

  def trigger_cc_database_fallback
    @trigger_lock.synchronize do
      return if @cc_dbs
      setup_cc_database
    end
  end

  def setup_cc_database
    prepare_cc_db
  end

  public

  def subscribe_database_path(database_type, database_path, geoip_plugin)
    if database_path.nil?
      if eula_manager.enabled?
        trigger_download

        logger.info "By not manually configuring a database path with `database =>`, you accepted and agreed MaxMind EULA. "\
                    "For more details please visit https://www.maxmind.com/en/geolite2/eula"

        @states[database_type].plugins.add(geoip_plugin)
        @trigger_lock.synchronize do
          @states.fetch(database_type).database_path
        end
      else
        trigger_cc_database_fallback
        @cc_dbs.fetch(database_type)
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

  def update!(database_type, updated_db_info)
    new_database_path = updated_db_info.path
    notify_plugins(database_type, :update, new_database_path) do |db_type, ids|
      logger.info("geoip filter plugin will use database #{new_database_path}",
                  :database_type => db_type, :pipeline_ids => ids) unless ids.empty?
    end
  end

  def expire!(database_type)
    notify_plugins(database_type, :expire) do |db_type, ids|
      logger.warn("geoip filter plugin will stop filtering and will tag all events with the '_geoip_expired_database' tag.",
                  :database_type => db_type, :pipeline_ids => ids)
    end
  end

  def create!(database_type, initial_db_info)
    @trigger_lock.synchronize do
      @states ||= {}

      if initial_db_info.pending?
        trigger_cc_database_fallback
        effective_database_path, is_eula = @cc_dbs.fetch(database_type), false
      else
        effective_database_path, is_eula = initial_db_info.path, true
      end

      @states[database_type] = DatabaseState.new(effective_database_path, is_eula)
    end
  end

  ##
  # @api testing
  def subscribed_plugins_count(database_type)
    @states&.dig(database_type)&.plugins&.size || 0
  end
  protected :subscribed_plugins_count

  ##
  # @api testing
  def eula_subscribed?
    @eula_subscriptions&.any?
  end
  protected :eula_subscribed?

  ##
  # @api testing
  def eula_subscription(database_type)
    @eula_subscriptions&.dig(database_type)
  end
  protected :eula_subscription

  ##
  # @api internal
  class DatabaseState
    attr_reader :plugins
    attr_accessor :database_path
    attr_reader :is_eula

    # @param initial_database_path [String]
    # @param is_eula [Boolean]
    def initialize(initial_database_path, is_eula)
      @plugins = Concurrent::Set.new
      @database_path = initial_database_path
      @is_eula = is_eula
    end
  end
end end end end
