# encoding: utf-8
require "logstash/environment"
require "logstash/errors"
require "logstash/config/cpu_core_strategy"
require "logstash/pipeline"
require "logstash/config/loader"
require "uri"
require "stud/trap"

LogStash::Environment.load_locale!

class LogStash::Agent
  attr_reader :logger

  def initialize(params)
    @logger = params[:logger]
    @pipelines = {}
    @pipeline_threads = {}
    @state = clean_state
    @config_loader = LogStash::Config::Loader.new(@logger, false)
    @config_str = params[:config_string]
    @config_path = params[:config_path]
    @auto_reload = params[:auto_reload]
  end

  def execute
    @thread = Thread.current
    @logger.info("starting agent", :state => @state)
    reload_state!
    if @auto_reload
      Stud.interval(5) { reload_state! }
    else
      sleep 0.5 until Stud.stop?
    end
  end

  def shutdown
    shutdown_pipelines
  end

  def reload_state!
    new_state = fetch_state
    if valid_state?(new_state)
      if new_state?(@state, new_state)
        @logger.warn("fetched new state. upgrading..", :state => new_state)
        upgrade_state(new_state)
      else
        @logger.debug("same state, ignoring..")
      end
    else
      @logger.error("invalid state", :state => new_state)
    end
  rescue => e
    @logger.fatal I18n.t("oops", :error => e)
    @logger.fatal e.backtrace if @logger.debug? || $DEBUGLIST.include?("stacktrace")
    return 1
  end

  private
  def add_pipeline(pipeline_id, config_str, settings = {})
    @pipelines[pipeline_id] = LogStash::Pipeline.new(config_str, settings)
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
    @logger.warn("stopping pipeline", :id => id)
    @pipelines[id].shutdown do
      # TODO uncomment once shutdown controller can be stopped
      #LogStash::ShutdownController.start(@pipelines[id])
    end
    @pipeline_threads[id].join
  end

  def shutdown_pipelines
    @pipelines.each do |id, pipeline|
      stop_pipeline(id)
      #pipeline.shutdown do
      #  ::LogStash::ShutdownController.start(pipeline)
      #end
    end
  end

  # Override the methods below if you're implementing your own agent
  def upgrade_state(new_state)
    stop_pipeline("base")
    add_pipeline("base", new_state)
  rescue Exception => e
    @logger.error("failed to update state", :new_state => new_state, :message => e.message, :backtrace => e.backtrace)
    @logger.warn("reverting to previous state", :state => @state)
    add_pipeline("base", @state) unless clean_state?
    @state
  else
    @state = new_state
  ensure
    start_pipeline("base") unless clean_state?
  end

  def fetch_state
    @config_loader.format_config(@config_path, @config_string)
  end

  def valid_state?(new_state)
    new_state.is_a?(String)
  end

  def new_state?(old_state, new_state)
    old_state != new_state
  end

  def clean_state
    ""
  end

  def clean_state?
    @state == clean_state
  end

end # class LogStash::Agent
