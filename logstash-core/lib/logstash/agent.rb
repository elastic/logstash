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
  attr_reader :logger, :pipelines

  def initialize(params)
    @logger = params[:logger]
    @auto_reload = params[:auto_reload]
    @pipelines = {}
     
    @node_name = params[:node_name] || Socket.gethostname
    @config_loader = LogStash::Config::Loader.new(@logger)
    @reload_interval = params[:reload_interval] || 3 # seconds
    @upgrade_mutex = Mutex.new
  end

  def execute
    @thread = Thread.current # this var is implicilty used by Stud.stop?
    @logger.info("starting agent")

    start_pipelines

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

  # register_pipeline adds a pipeline to the agent's state
  # @param pipeline_id [String] pipeline string identifier
  # @param settings [Hash] settings for the pipeline. keys should be symbols
  # such as :pipeline_workers and :pipeline_batch_delay
  def register_pipeline(pipeline_id, settings)
    pipeline = create_pipeline(settings.merge(:pipeline_id => pipeline_id))
    return unless pipeline.is_a?(LogStash::Pipeline)
    @pipelines[pipeline_id] = pipeline
  end

  def reload_state!
    @upgrade_mutex.synchronize do
      @pipelines.each { |pipeline_id, _| reload_pipeline!(pipeline_id) }
    end
  rescue => e
    @logger.error I18n.t("oops", :error => e, :backtrace => e.backtrace)
    return 1
  end

  def shutdown
    shutdown_pipelines
  end

  private
  def node_uuid
    @node_uuid ||= SecureRandom.uuid
  end

  def create_pipeline(settings)
    begin
      config = fetch_config(settings[:config_path], settings[:config_string])
    rescue => e
      @logger.error("failed to fetch pipeline configuration", :message => e.message)
      return
    end

    begin
      LogStash::Pipeline.new(config, settings)
    rescue => e
      @logger.error("fetched an invalid config", :config => config, :reason => e.message)
      return
    end
  end

  def fetch_config(config_path, config_string)
    @config_loader.format_config(config_path, config_string)
  end

  def reload_pipeline!(id)
    old_pipeline = @pipelines[id]
    new_pipeline = create_pipeline(old_pipeline.original_settings)
    return if new_pipeline.nil?

    if old_pipeline.config_str == new_pipeline.config_str
      @logger.debug("no configuration change for pipeline",
                    :pipeline => id, :config => old_pipeline.config_str)
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

  def running_pipelines?
    @upgrade_mutex.synchronize do
      @pipelines.select {|pipeline_id, _| running_pipeline?(pipeline_id) }.any?
    end
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

end # class LogStash::Agent
