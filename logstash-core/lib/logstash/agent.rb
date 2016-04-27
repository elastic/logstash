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
require "stud/trap"
require "logstash/config/loader"
require "uri"
require "socket"
require "securerandom"

LogStash::Environment.load_locale!

module LogStash class Agent
  STARTED_AT = Time.now.freeze

  attr_reader :metric, :node_name, :pipelines, :logger

  # initialize method for LogStash::Agent
  # @param params [Hash] potential parameters are:
  #   :node_name [String] - identifier for the agent
  #   :auto_reload [Boolean] - enable reloading of pipelines
  #   :reload_interval [Integer] - reload pipelines every X seconds
  #   :logger [Cabin::Channel] - logger instance
  def initialize(params = {})
    puts "initializing agent"
    @logger = params["logger"]
    @settings = LogStash::SETTINGS
    @node_name = @settings.get_value("node.name")
    @web_api_http_host = @settings.get_value("web_api.http.host")
    @web_api_http_port = @settings.get_value("web_api.http.port")

    @config_loader = LogStash::Config::Loader.new(@logger)
    @auto_reload = @settings.get_value("config.auto_reload")
    @reload_interval = @settings.get_value("config.reload_interval")
    @collect_metric = @settings.get_value("metric.collect")

    @pipelines = {}
    @upgrade_mutex = Mutex.new
    setup_metric_collection
  end

  def execute
    @thread = Thread.current # this var is implicilty used by Stud.stop?
    @logger.info("starting agent")

    start_background_services
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
  def register_pipeline(pipeline_id, pipeline_settings)
    id_setting = LogStash::Setting.new("pipeline.id", String, pipeline_id)
    pipeline_settings.register(id_setting)
    metric_setting = LogStash::Setting.new("metric", Object, @metric)
    pipeline_settings.register(metric_setting)

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
      @pipelines.each do |pipeline_id, _|
        begin
          reload_pipeline!(pipeline_id)
        rescue => e
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

  def shutdown
    stop_background_services
    stop_webserver
    shutdown_pipelines
  end

  def node_uuid
    @node_uuid ||= SecureRandom.uuid
  end

  def running_pipelines?
    @upgrade_mutex.synchronize do
      @pipelines.select {|pipeline_id, _| running_pipeline?(pipeline_id) }.any?
    end
  end

  private
  def start_webserver
    options = {:http_host => @web_api_http_host, :http_port => @web_api_http_port }
    @webserver = LogStash::WebServer.new(@logger, options)
    Thread.new(@webserver) do |webserver|
      LogStash::Util.set_thread_name("Api Webserver")
      webserver.run
    end
  end

  def stop_webserver
    @webserver.stop if @webserver
  end

  def start_background_services
    if collect_metrics?
      @logger.debug("Agent: Starting metric periodic pollers")
      @periodic_pollers.start
    end
  end

  def stop_background_services
    if collect_metrics?
      @logger.debug("Agent: Stopping metric periodic pollers")
      @periodic_pollers.stop
    end
  end

  def setup_metric_collection
    if collect_metrics?
      @logger.debug("Agent: Configuring metric collection")
      LogStash::Instrument::Collector.instance.agent = self
      @metric = LogStash::Instrument::Metric.new
    else
      @metric = LogStash::Instrument::NullMetric.new
    end

    @periodic_pollers = LogStash::Instrument::PeriodicPollers.new(metric)
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
      LogStash::Pipeline.new(config, settings)
    rescue => e
      @logger.error("fetched an invalid config", :config => config, :reason => e.message)
      return
    end
  end

  def fetch_config(settings)
    @config_loader.format_config(settings.get_value("config.path"), settings.get_value("config.string"))
  end

  # since this method modifies the @pipelines hash it is
  # wrapped in @upgrade_mutex in the parent call `reload_state!`
  def reload_pipeline!(id)
    old_pipeline = @pipelines[id]
    new_config = fetch_config(old_pipeline.original_settings)
    if old_pipeline.config_str == new_config
      @logger.debug("no configuration change for pipeline",
                    :pipeline => id, :config => new_config)
      return
    end

    new_pipeline = create_pipeline(old_pipeline.original_settings, new_config)
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
    @logger.info("starting pipeline", :id => id)

    # Reset the current collected stats,
    # starting a pipeline with a new configuration should be the same as restarting
    # logstash.
    reset_collector

    Thread.new do
      LogStash::Util.set_thread_name("pipeline.#{id}")
      begin
        pipeline.run
      rescue => e
        @logger.error("Pipeline aborted due to error", :exception => e, :backtrace => e.backtrace)
      end
    end
    sleep 0.01 until pipeline.ready?
  end

  def stop_pipeline(id)
    pipeline = @pipelines[id]
    return unless pipeline
    @logger.warn("stopping pipeline", :id => id)
    pipeline.shutdown { LogStash::ShutdownWatcher.start(pipeline) }
    @pipelines[id].thread.join
  end

  def start_pipelines
    @pipelines.each { |id, _| start_pipeline(id) }
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
    @pipelines[pipeline_id] = new_pipeline
    start_pipeline(pipeline_id)
  end

  def clean_state?
    @pipelines.empty?
  end

  def reset_collector
    Instrument::Collector.instance.clear
  end
end end
