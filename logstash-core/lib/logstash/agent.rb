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
  attr_reader :logger, :state

  def initialize(params)
    @logger = params[:logger]
    @pipelines = {}
     
    @node_name = options[:node_name] || Socket.gethostname
    @pipeline_threads = {}
    @config_loader = LogStash::Config::Loader.new(@logger, false)
    @config_string = params[:config_string]
    @config_path = params[:config_path]
    @auto_reload = params[:auto_reload]
    @pipeline_settings = params[:pipeline_settings]
    @reload_interval = params[:reload_interval] || 5 # seconds
    @upgrade_mutex = Mutex.new
    # @state represents the necessary information for the agent's lifecycle.
    # this base implementation uses the configuration string itself as state.
    # if fetch_state returns a different string, it is regarded as new state
    # and upgrade_state will take care of stopping the previous pipeline and
    # starting a new one
    # a subclass of this base Agent could use more complex state objects such
    # as a hash map containing versioning, update_at timestamp, etc.
    @state = clean_state
  end

  def execute
    @thread = Thread.current
    @logger.info("starting agent", :state => @state)

    if @auto_reload
      Stud.interval(@reload_interval) do
        if clean_state? || running_pipelines?
          reload_state!
        else
          break
        end
      end
    else
      reload_state!
      while !Stud.stop?
        if clean_state? || running_pipelines?
          sleep 0.5
        else
          break
        end
      end
    end
  end

  def shutdown
    shutdown_pipelines
  end

  def reload_state
    new_state = fetch_state
    if valid_state?(new_state)
      if new_state?(@state, new_state)
        @logger.warn("fetched new state. upgrading..", :state => new_state)
        @upgrade_mutex.synchronize { upgrade_state(new_state) }
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
    @logger.warn("stopping pipeline", :id => id)
    @pipelines[id].shutdown do
      LogStash::ShutdownController.start(@pipelines[id], @pipeline_threads[id])
    end
    @pipeline_threads[id].join
  end

  def shutdown_pipelines
    @pipelines.each { |id, _| stop_pipeline(id) }
  end

  def running_pipelines?
    @upgrade_mutex.synchronize do
      @pipeline_threads.select {|_, pipeline| pipeline.alive? }.any?
    end
  end

  # Override the methods below if you're implementing your own agent
  def upgrade_state(new_state)
    stop_pipeline("base")
    add_pipeline("base", new_state, @pipeline_settings)
  rescue => e
    @logger.error("failed to update state", :new_state => new_state, :message => e.message, :backtrace => e.backtrace)
    @logger.warn("reverting to previous state", :state => @state)
    add_pipeline("base", @state, @pipeline_settings) unless clean_state?
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
