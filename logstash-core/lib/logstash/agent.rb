# encoding: utf-8
require "logstash/environment"
require "logstash/errors"
require "logstash/config/cpu_core_strategy"
require "logstash/instrument/collector"
require "logstash/instrument/metric"
require "logstash/instrument/periodic_pollers"
require "logstash/instrument/collector"
require "logstash/instrument/metric"
require "logstash/pipeline"
require "logstash/webserver"
require "logstash/event_dispatcher"
require "stud/trap"
require "logstash/config/loader"
require "uri"
require "socket"
require "securerandom"

LogStash::Environment.load_locale!

class LogStash::Agent
  include LogStash::Util::Loggable
  STARTED_AT = Time.now.freeze

  attr_reader :metric, :name, :pipelines, :settings, :webserver, :dispatcher
  attr_accessor :logger

  # initialize method for LogStash::Agent
  # @param params [Hash] potential parameters are:
  #   :name [String] - identifier for the agent
  #   :auto_reload [Boolean] - enable reloading of pipelines
  #   :reload_interval [Integer] - reload pipelines every X seconds
  def initialize(settings = LogStash::SETTINGS)
    @logger = self.class.logger
    @settings = settings
    @auto_reload = setting("config.reload.automatic")

    @pipelines = {}
    @name = setting("node.name")
    @http_host = setting("http.host")
    @http_port = setting("http.port")
    @http_environment = setting("http.environment")
    # Generate / load the persistent uuid
    id

    @config_loader = LogStash::Config::Loader.new(@logger)
    @reload_interval = setting("config.reload.interval")
    @upgrade_mutex = Mutex.new

    @collect_metric = setting("metric.collect")

    # Create the collectors and configured it with the library
    configure_metrics_collectors

    @pipeline_reload_metric = metric.namespace([:stats, :pipelines])
    @instance_reload_metric = metric.namespace([:stats, :reloads])

    @dispatcher = LogStash::EventDispatcher.new(self)
    LogStash::PLUGIN_REGISTRY.hooks.register_emitter(self.class, dispatcher)
    dispatcher.fire(:after_initialize)
  end

  def execute
    @thread = Thread.current # this var is implicitly used by Stud.stop?
    @logger.debug("starting agent")

    start_pipelines
    start_webserver

    return 1 if clean_state?

    Stud.stoppable_sleep(@reload_interval) # sleep before looping

    if @auto_reload
      Stud.interval(@reload_interval) { reload_state! }
    else
      while !Stud.stop?
        if clean_state? || running_user_defined_pipelines?
          sleep(0.5)
        else
          break
        end
      end
    end
  end

  # register_pipeline - adds a pipeline to the agent's state
  # @param pipeline_id [String] pipeline string identifier
  # @param settings [Hash] settings that will be passed when creating the pipeline.
  #   keys should be symbols such as :pipeline_workers and :pipeline_batch_delay
  def register_pipeline(settings)
    pipeline_settings = settings.clone
    pipeline_id = pipeline_settings.get("pipeline.id")

    pipeline = create_pipeline(pipeline_settings)
    return unless pipeline.is_a?(LogStash::Pipeline)
    if @auto_reload && !pipeline.reloadable?
      @logger.error(I18n.t("logstash.agent.non_reloadable_config_register"),
                    :pipeline_id => pipeline_id,
                    :plugins => pipeline.non_reloadable_plugins.map(&:class))
      return
    end
    @pipelines[pipeline_id] = pipeline
  end

  def reload_state!
    @upgrade_mutex.synchronize do
      @pipelines.each do |pipeline_id, pipeline|
        next if pipeline.settings.get("config.reload.automatic") == false
        begin
          reload_pipeline!(pipeline_id)
        rescue => e
          @instance_reload_metric.increment(:failures)
          @pipeline_reload_metric.namespace([pipeline_id.to_sym, :reloads]).tap do |n|
            n.increment(:failures)
            n.gauge(:last_error, { :message => e.message, :backtrace => e.backtrace})
            n.gauge(:last_failure_timestamp, LogStash::Timestamp.now)
          end
          @logger.error(I18n.t("oops"), :message => e.message, :class => e.class.name, :backtrace => e.backtrace)
        end
      end
    end
  end

  # Calculate the Logstash uptime in milliseconds
  #
  # @return [Fixnum] Uptime in milliseconds
  def uptime
    ((Time.now.to_f - STARTED_AT.to_f) * 1000.0).to_i
  end

  def stop_collecting_metrics
    @periodic_pollers.stop
  end

  def shutdown
    stop_collecting_metrics
    stop_webserver
    shutdown_pipelines
  end

  def id
    return @id if @id

    uuid = nil
    if ::File.exists?(id_path)
      begin
        uuid = ::File.open(id_path) {|f| f.each_line.first.chomp }
      rescue => e
        logger.warn("Could not open persistent UUID file!",
                    :path => id_path,
                    :error => e.message,
                    :class => e.class.name)
      end
    end

    if !uuid
      uuid = SecureRandom.uuid
      logger.info("No persistent UUID file found. Generating new UUID",
                  :uuid => uuid,
                  :path => id_path)
      begin
        ::File.open(id_path, 'w') {|f| f.write(uuid) }
      rescue => e
        logger.warn("Could not write persistent UUID file! Will use ephemeral UUID",
                    :uuid => uuid,
                    :path => id_path,
                    :error => e.message,
                    :class => e.class.name)
      end
    end

    @id = uuid
  end

  def id_path
    @id_path ||= ::File.join(settings.get("path.data"), "uuid")
  end

  def running_pipelines
    @upgrade_mutex.synchronize do
      @pipelines.select {|pipeline_id, _| running_pipeline?(pipeline_id) }
    end
  end

  def running_pipelines?
    @upgrade_mutex.synchronize do
      @pipelines.select {|pipeline_id, _| running_pipeline?(pipeline_id) }.any?
    end
  end

  def running_user_defined_pipelines?
    @upgrade_mutex.synchronize do
      @pipelines.select do |pipeline_id, _|
        pipeline = @pipelines[pipeline_id]
        pipeline.running? && !pipeline.system?
      end.any?
    end
  end

  def close_pipeline(id)
    pipeline = @pipelines[id]
    if pipeline
      @logger.warn("closing pipeline", :id => id)
      pipeline.close
    end
  end

  def close_pipelines
    @pipelines.each  do |id, _|
      close_pipeline(id)
    end
  end

  private

  def start_webserver
    options = {:http_host => @http_host, :http_ports => @http_port, :http_environment => @http_environment }
    @webserver = LogStash::WebServer.new(@logger, self, options)
    Thread.new(@webserver) do |webserver|
      LogStash::Util.set_thread_name("Api Webserver")
      webserver.run
    end
  end

  def stop_webserver
    @webserver.stop if @webserver
  end

  def configure_metrics_collectors
    @collector = LogStash::Instrument::Collector.new

    @metric = if collect_metrics?
      @logger.debug("Agent: Configuring metric collection")
      LogStash::Instrument::Metric.new(@collector)
    else
      LogStash::Instrument::NullMetric.new(@collector)
    end

    @periodic_pollers = LogStash::Instrument::PeriodicPollers.new(@metric, settings.get("queue.type"), self)
    @periodic_pollers.start
  end

  def reset_pipeline_metrics(id)
    # selectively reset metrics we don't wish to keep after reloading
    # these include metrics about the plugins and number of processed events
    # we want to keep other metrics like reload counts and error messages
    @collector.clear("stats/pipelines/#{id}/plugins")
    @collector.clear("stats/pipelines/#{id}/events")
  end

  def collect_metrics?
    @collect_metric
  end

  def increment_reload_failures_metrics(id, message, backtrace = nil)
    @instance_reload_metric.increment(:failures)
    @pipeline_reload_metric.namespace([id.to_sym, :reloads]).tap do |n|
      n.increment(:failures)
      n.gauge(:last_error, { :message => message, :backtrace =>backtrace})
      n.gauge(:last_failure_timestamp, LogStash::Timestamp.now)
    end
    if @logger.debug?
      @logger.error("Cannot create pipeline", :reason => message, :backtrace => backtrace)
    else
      @logger.error("Cannot create pipeline", :reason => message)
    end
  end

  # create a new pipeline with the given settings and config, if the pipeline initialization failed
  # increment the failures metrics
  # @param settings [Settings] the setting for the new pipelines
  # @param config [String] the configuration string or nil to fetch the configuration per settings
  # @return [Pipeline] the new pipeline or nil if it failed
  def create_pipeline(settings, config = nil)
    if config.nil?
      begin
        config = fetch_config(settings)
      rescue => e
        @logger.error("failed to fetch pipeline configuration", :message => e.message)
        return nil
      end
    end

    begin
      LogStash::Pipeline.new(config, settings, metric)
    rescue => e
      increment_reload_failures_metrics(settings.get("pipeline.id"), e.message, e.backtrace)
      return nil
    end
  end

  def fetch_config(settings)
    @config_loader.format_config(settings.get("path.config"), settings.get("config.string"))
  end

  # reload_pipeline trys to reloads the pipeline with id using a potential new configuration if it changed
  # since this method modifies the @pipelines hash it is wrapped in @upgrade_mutex in the parent call `reload_state!`
  # @param id [String] the pipeline id to reload
  def reload_pipeline!(id)
    old_pipeline = @pipelines[id]
    new_config = fetch_config(old_pipeline.settings)

    if old_pipeline.config_str == new_config
      @logger.debug("no configuration change for pipeline", :pipeline => id)
      return
    end

    # check if this pipeline is not reloadable. it should not happen as per the check below
    # but keep it here as a safety net if a reloadable pipeline was reloaded with a non reloadable pipeline
    if !old_pipeline.reloadable?
      @logger.error("pipeline is not reloadable", :pipeline => id)
      return
    end

    # BasePipeline#initialize will compile the config, and load all plugins and raise an exception
    # on an invalid configuration
    begin
      pipeline_validator = LogStash::BasePipeline.new(new_config, old_pipeline.settings)
    rescue => e
      increment_reload_failures_metrics(id, e.message, e.backtrace)
      return
    end

    # check if the new pipeline will be reloadable in which case we want to log that as an error and abort
    if !pipeline_validator.reloadable?
      @logger.error(I18n.t("logstash.agent.non_reloadable_config_reload"), :pipeline_id => id, :plugins => pipeline_validator.non_reloadable_plugins.map(&:class))
      increment_reload_failures_metrics(id, "non reloadable pipeline")
      return
    end

    # we know configis valid so we are fairly comfortable to first stop old pipeline and then start new one
    upgrade_pipeline(id, old_pipeline.settings, new_config)
  end

  # upgrade_pipeline first stops the old pipeline and starts the new one
  # this method exists only for specs to be able to expects this to be executed
  # @params pipeline_id [String] the pipeline id to upgrade
  # @params settings [Settings] the settings for the new pipeline
  # @params new_config [String] the new pipeline config
  def upgrade_pipeline(pipeline_id, settings, new_config)
    @logger.warn("fetched new config for pipeline. upgrading..", :pipeline => pipeline_id, :config => new_config)

    # first step: stop the old pipeline.
    # IMPORTANT: a new pipeline with same settings should not be instantiated before the previous one is shutdown

    stop_pipeline(pipeline_id)
    reset_pipeline_metrics(pipeline_id)

    # second step create and start a new pipeline now that the old one is shutdown

    new_pipeline = create_pipeline(settings, new_config)
    if new_pipeline.nil?
      # this is a scenario where the configuration is valid (compilable) but the new pipeline refused to start
      # and at this point NO pipeline is running
      @logger.error("failed to create the reloaded pipeline and no pipeline is currently running", :pipeline => pipeline_id)
      increment_reload_failures_metrics(pipeline_id, "failed to create the reloaded pipeline")
      return
    end

    ### at this point pipeline#close must be called if upgrade_pipeline does not succeed

    # check if the new pipeline will be reloadable in which case we want to log that as an error and abort. this should normally not
    # happen since the check should be done in reload_pipeline! prior to get here.
    if !new_pipeline.reloadable?
      @logger.error(I18n.t("logstash.agent.non_reloadable_config_reload"), :pipeline_id => pipeline_id, :plugins => new_pipeline.non_reloadable_plugins.map(&:class))
      increment_reload_failures_metrics(pipeline_id, "non reloadable pipeline")
      new_pipeline.close
      return
    end

    # @pipelines[pipeline_id] must be initialized before #start_pipeline below which uses it
    @pipelines[pipeline_id] = new_pipeline

    if !start_pipeline(pipeline_id)
      @logger.error("failed to start the reloaded pipeline and no pipeline is currently running", :pipeline => pipeline_id)
      # do not call increment_reload_failures_metrics here since #start_pipeline already does it on failure
      new_pipeline.close
      return
    end

    # pipeline started successfully, update reload success metrics
    @instance_reload_metric.increment(:successes)
    @pipeline_reload_metric.namespace([pipeline_id.to_sym, :reloads]).tap do |n|
      n.increment(:successes)
      n.gauge(:last_success_timestamp, LogStash::Timestamp.now)
    end
  end

  def start_pipeline(id)
    pipeline = @pipelines[id]
    return unless pipeline.is_a?(LogStash::Pipeline)
    return if pipeline.ready?
    @logger.debug("starting pipeline", :id => id)
    t = Thread.new do
      LogStash::Util.set_thread_name("pipeline.#{id}")
      begin
        pipeline.run
      rescue => e
        @instance_reload_metric.increment(:failures)
        @pipeline_reload_metric.namespace([id.to_sym, :reloads]).tap do |n|
          n.increment(:failures)
          n.gauge(:last_error, { :message => e.message, :backtrace => e.backtrace})
          n.gauge(:last_failure_timestamp, LogStash::Timestamp.now)
        end
        @logger.error("Pipeline aborted due to error", :exception => e, :backtrace => e.backtrace)

        # TODO: this is weird, why dont we return directly here? any reason we need to enter the while true loop below?!
      end
    end
    while true do
      if !t.alive?
        return false
      elsif pipeline.running?
        return true
      else
        sleep 0.01
      end
    end
  end

  def stop_pipeline(id)
    pipeline = @pipelines[id]
    return unless pipeline
    @logger.warn("stopping pipeline", :id => id)
    pipeline.shutdown { LogStash::ShutdownWatcher.start(pipeline) }
    @pipelines[id].thread.join
  end

  def start_pipelines
    @instance_reload_metric.increment(:successes, 0)
    @instance_reload_metric.increment(:failures, 0)
    @pipelines.each do |id, pipeline|
      start_pipeline(id)
      pipeline.collect_stats
      # no reloads yet, initialize all the reload metrics
      init_pipeline_reload_metrics(id)
    end
  end

  def shutdown_pipelines
    @pipelines.each { |id, _| stop_pipeline(id) }
  end

  def running_pipeline?(pipeline_id)
    thread = @pipelines[pipeline_id].thread
    thread.is_a?(Thread) && thread.alive?
  end

  def clean_state?
    @pipelines.empty?
  end

  def setting(key)
    @settings.get(key)
  end

  def init_pipeline_reload_metrics(id)
    @pipeline_reload_metric.namespace([id.to_sym, :reloads]).tap do |n|
      n.increment(:successes, 0)
      n.increment(:failures, 0)
      n.gauge(:last_error, nil)
      n.gauge(:last_success_timestamp, nil)
      n.gauge(:last_failure_timestamp, nil)
    end
  end
end # class LogStash::Agent
