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
require "uri"
require "socket"
require "securerandom"

LogStash::Environment.load_locale!

class LogStash::Agent

  attr_writer :logger
  attr_reader :metric, :debug, :node_name, :started_at, :pipelines

  def initialize(options = {})
    @pipelines = {}
    @node_name = options[:node_name] || Socket.gethostname
    @collect_metric = options.fetch(:collect_metric, false)
    @logger = options[:logger]
    @debug  = options.fetch(:debug, false)

    @started_at = Time.now

    configure_metric
    @node_name = options[:node_name] || Socket.gethostname
  end

  def execute
    # Make SIGINT/SIGTERM shutdown the pipeline.
    sigint_id = trap_sigint()
    sigterm_id = trap_sigterm()

    start_background_services

    @pipelines.each { |_, p| Thread.new { p.run } }
    start_webserver

    sleep(1) while true
    return 0
  rescue => e
    @logger.fatal I18n.t("oops", :error => e)
    @logger.fatal e.backtrace if @logger.debug? || $DEBUGLIST.include?("stacktrace")
    return 1
  ensure
    stop_background_services

    Stud::untrap("INT", sigint_id) unless sigint_id.nil?
    Stud::untrap("TERM", sigterm_id) unless sigterm_id.nil?
  end # def execute

  def add_pipeline(pipeline_id, config_str, settings = {})
    settings.merge!(:pipeline_id => pipeline_id,
                    :metric => metric)

    @pipelines[pipeline_id] = LogStash::Pipeline.new(config_str, settings)
  end

  def node_uuid
    @node_uuid ||= SecureRandom.uuid
  end

  # Calculate the Logstash uptime in milliseconds
  #
  # @return [Fixnum] Uptime in milliseconds
  def uptime
    ((Time.now.to_f - started_at.to_f) * 1000.0).to_i
  end

  private

  def start_webserver
    options = { :debug => debug }
    @webserver = LogStash::WebServer.new(@logger, options)
    Thread.new(@webserver) do |webserver|
      webserver.run
    end
  end

  def stop_webserver
    @webserver.stop
  end

  def start_background_services
    if collect_metric?
      @logger.debug("Agent: Starting metric periodic pollers")
      @periodic_pollers.start
    end
  end

  def stop_background_services
    if collect_metric?
      @logger.debug("Agent: Stopping metric periodic pollers")
      @periodic_pollers.stop
    end
  end

  def configure_metric
    if collect_metric?
      @logger.debug("Agent: Configuring metric collection")
      @metric = LogStash::Instrument::Metric.create
    else
      @metric = LogStash::Instrument::NullMetric.new
    end

    @periodic_pollers = LogStash::Instrument::PeriodicPollers.new(metric)
  end

  def collect_metric?
    @collect_metric
  end

  def pipeline_exist?(pipeline_id)
    !@pipelines[pipeline_id].nil?
  end

  # Emit a warning message.
  def warn(message)
    # For now, all warnings are fatal.
    raise LogStash::ConfigurationError, message
  end # def warn

  # Emit a failure message and abort.
  def fail(message)
    raise LogStash::ConfigurationError, message
  end # def fail

  def shutdown_pipelines
    @pipelines.each do |_, pipeline|
      pipeline.shutdown do
        ::LogStash::ShutdownWatcher.start(pipeline)
      end
    end
  end

  def trap_sigterm
    Stud::trap("TERM") do
      @logger.warn(I18n.t("logstash.agent.sigterm"))
      shutdown_pipelines
      stop_webserver
    end
  end

  def trap_sigint
    Stud::trap("INT") do
      if @interrupted_once
        @logger.fatal(I18n.t("logstash.agent.forced_sigint"))
        exit
      else
        @logger.warn(I18n.t("logstash.agent.sigint"))
        Thread.new(@logger) {|logger| sleep 5; logger.warn(I18n.t("logstash.agent.slow_shutdown")) }
        @interrupted_once = true
        shutdown_pipelines
        stop_webserver
      end
    end
  end
end # class LogStash::Agent
