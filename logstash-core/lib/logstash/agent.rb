# encoding: utf-8
require "logstash/environment"
require "logstash/errors"
require "logstash/config/cpu_core_strategy"
require "logstash/pipeline"
require "stud/trap"
require "logstash/config/loader"
require "uri"
require "socket"
require "securerandom"

LogStash::Environment.load_locale!

class LogStash::Agent
  attr_reader :logger

  attr_writer :logger
  attr_reader :node_name

  def initialize(logger, options = {})
    @logger = logger
    @pipelines = {}
     
    @node_name = options[:node_name] || Socket.gethostname
    @pipeline_threads = {}
    @state = ""
    @config_loader = LogStash::Config::Loader.new(@logger, false)
    @config_str = config_string
    @config_path = config_path
  end

  def execute
    sigint_id = trap_sigint()
    sigterm_id = trap_sigterm()

    @logger.info "starting agent"
    loop do
      new_state = fetch_state
      if valid_state?(new_state)
        if new_state?(@state, new_state)
          @logger.info "new state: #{new_state}"
          upgrade_state(new_state)
        else
          @logger.debug("same state, ignoring..")
        end
      else
        @logger.error("invalid state #{new_state}")
      end
      sleep 10
    end
    return 0
  rescue => e
    @logger.fatal I18n.t("oops", :error => e)
    @logger.fatal e.backtrace if @logger.debug? || $DEBUGLIST.include?("stacktrace")
    return 1
  ensure
    Stud::untrap("INT", sigint_id) unless sigint_id.nil?
    Stud::untrap("TERM", sigterm_id) unless sigterm_id.nil?
  end

  def add_pipeline(pipeline_id, config_str, settings = {})
    @pipelines[pipeline_id] = LogStash::Pipeline.new(config_str, settings.merge(:pipeline_id => pipeline_id))
  end

  def node_uuid
    @node_uuid ||= SecureRandom.uuid
  end

  def start_pipeline(id)
    return unless @pipelines[id]
    @logger.info("starting pipeline", :id => id)
    @pipeline_threads[id] = Thread.new do
      LogStash::Util.set_thread_name("pipeline.#{id}")
      @pipelines[id].run
    end
  end

  def stop_pipeline(id)
    return unless @pipelines[id]
    @logger.info("stopping pipeline", :id => id)
    @pipelines[id].shutdown do
      # TODO uncomment once shutdown controller can be stopped
      #LogStash::ShutdownController.start(@pipelines[id])
    end
    @pipeline_threads[id].join
  end

  def shutdown_pipeline(id)
    return unless @pipelines[id]
    @pipelines[id].shutdown do
      ::LogStash::ShutdownController.start(@pipelines[id])
    end
  end

  def shutdown_pipelines
    @pipelines.each do |_, pipeline|
      pipeline.shutdown do
        ::LogStash::ShutdownController.start(pipeline)
      end
    end
  end

  private
  # Emit a warning message.
  def warn(message)
    # For now, all warnings are fatal.
    raise LogStash::ConfigurationError, message
  end # def warn

  # Emit a failure message and abort.
  def fail(message)
    raise LogStash::ConfigurationError, message
  end # def fail

  def fetch_state
    @config_loader.format_config(@config_path, @config_string)
  end

  def valid_state?(new_state)
    new_state.is_a?(String)
  end

  def new_state?(old_state, new_state)
    old_state != new_state
  end

  def upgrade_state(new_state)
    stop_pipeline("base")
    add_pipeline("base", new_state)
  rescue Exception => e
    @logger.error("failed to update state", :new_state => new_state, :message => e.message, :backtrace => e.backtrace)
    @logger.warn("reverting to previous state", :state => @state)
    add_pipeline("base", @state) unless @state.empty?
    @state
  else
    @state = new_state
  ensure
    start_pipeline("base")
  end

  def trap_sigterm
    Stud::trap("TERM") do
      @logger.warn(I18n.t("logstash.agent.sigterm"))
      shutdown_pipelines
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
      end
    end
  end
end # class LogStash::Agent
