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

    @reload_metric = metric.namespace([:stats, :pipelines])

    @dispatcher = LogStash::EventDispatcher.new(self)
    LogStash::PLUGIN_REGISTRY.hooks.register_emitter(self.class, dispatcher)
    dispatcher.fire(:after_initialize)
  end

  def execute
    @thread = Thread.current # this var is implicilty used by Stud.stop?
    @logger.debug("starting agent")

    start_pipelines
    start_webserver

    return 1 if clean_state?

    Stud.stoppable_sleep(@reload_interval) # sleep before looping

    if @auto_reload
      Stud.interval(@reload_interval) { reload_state! }
    else
      while !Stud.stop?
        if clean_state? || running_pipelines?
          sleep 0.5
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
  def register_pipeline(pipeline_id, settings = @settings)
    pipeline_settings = settings.clone
    pipeline_settings.set("pipeline.id", pipeline_id)

    pipeline = create_pipeline(pipeline_settings)
    return unless pipeline.is_a?(LogStash::Pipeline)
    if @auto_reload && pipeline.non_reloadable_plugins.any?
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
          @reload_metric.namespace([pipeline_id.to_sym, :reloads]).tap do |n|
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
    @collector.stop
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

  def running_pipelines?
    @upgrade_mutex.synchronize do
      @pipelines.select {|pipeline_id, _| running_pipeline?(pipeline_id) }.any?
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


    @periodic_pollers = LogStash::Instrument::PeriodicPollers.new(@metric)
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

  def create_pipeline(settings, config=nil)
    if config.nil?
      begin
        config = fetch_config(settings)
      rescue => e
        @logger.error("failed to fetch pipeline configuration", :message => e.message)
        return
      end
    end

    begin
      LogStash::Pipeline.new(config, settings, metric)
    rescue => e
      @reload_metric.namespace([settings.get("pipeline.id").to_sym, :reloads]).tap do |n|
        n.increment(:failures)
        n.gauge(:last_error, { :message => e.message, :backtrace => e.backtrace})
        n.gauge(:last_failure_timestamp, LogStash::Timestamp.now)
      end
      if @logger.debug?
        @logger.error("fetched an invalid config", :config => config, :reason => e.message, :backtrace => e.backtrace)
      else
        @logger.error("fetched an invalid config", :config => config, :reason => e.message)
      end
      return
    end
  end

  def fetch_config(settings)
    @config_loader.format_config(settings.get("path.config"), settings.get("config.string"))
  end

  # since this method modifies the @pipelines hash it is
  # wrapped in @upgrade_mutex in the parent call `reload_state!`
  def reload_pipeline!(id)
    old_pipeline = @pipelines[id]
    new_config = fetch_config(old_pipeline.settings)
    if old_pipeline.config_str == new_config
      @logger.debug("no configuration change for pipeline",
                    :pipeline => id, :config => new_config)
      return
    end

    new_pipeline = create_pipeline(old_pipeline.settings, new_config)

    return if new_pipeline.nil?

    if new_pipeline.non_reloadable_plugins.any?
      @logger.error(I18n.t("logstash.agent.non_reloadable_config_reload"),
                    :pipeline_id => id,
                    :plugins => new_pipeline.non_reloadable_plugins.map(&:class))
      return
    else
      @logger.warn("fetched new config for pipeline. upgrading..",
                   :pipeline => id, :config => new_pipeline.config_str)
      upgrade_pipeline(id, new_pipeline)
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
        @reload_metric.namespace([id.to_sym, :reloads]).tap do |n|
          n.increment(:failures)
          n.gauge(:last_error, { :message => e.message, :backtrace => e.backtrace})
          n.gauge(:last_failure_timestamp, LogStash::Timestamp.now)
        end
        @logger.error("Pipeline aborted due to error", :exception => e, :backtrace => e.backtrace)
      end
    end
    while true do
      if !t.alive?
        return false
      elsif pipeline.ready?
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
    @pipelines.each do |id, _|
      start_pipeline(id)
      # no reloads yet, initalize all the reload metrics
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

  def upgrade_pipeline(pipeline_id, new_pipeline)
    stop_pipeline(pipeline_id)
    reset_pipeline_metrics(pipeline_id)
    @pipelines[pipeline_id] = new_pipeline
    if start_pipeline(pipeline_id) # pipeline started successfuly
      @reload_metric.namespace([pipeline_id.to_sym, :reloads]).tap do |n|
        n.increment(:successes)
        n.gauge(:last_success_timestamp, LogStash::Timestamp.now)
      end
    end
  end

  def clean_state?
    @pipelines.empty?
  end

  def setting(key)
    @settings.get(key)
  end

  def init_pipeline_reload_metrics(id)
    @reload_metric.namespace([id.to_sym, :reloads]).tap do |n|
      n.increment(:successes, 0)
      n.increment(:failures, 0)
      n.gauge(:last_error, nil)
      n.gauge(:last_success_timestamp, nil)
      n.gauge(:last_failure_timestamp, nil)
    end
  end
end # class LogStash::Agent
