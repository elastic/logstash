# encoding: utf-8
require "clamp" # gem 'clamp'
require "logstash/environment"
require "logstash/errors"
require "logstash/config/cpu_core_strategy"
require "stud/trap"
require "logstash/config/loader"
require "uri"
require "net/http"
require "logstash/pipeline"

class LogStash::Agent < Clamp::Command

  attr_reader :pipelines, :config_loader

  DEFAULT_INPUT = "input { stdin { type => stdin } }"
  DEFAULT_OUTPUT = "output { stdout { codec => rubydebug } }"

  option ["-f", "--config"], "CONFIG_PATH",
    I18n.t("logstash.agent.flag.config"),
    :attribute_name => :config_path

  option "-e", "CONFIG_STRING",
    I18n.t("logstash.agent.flag.config-string",
           :default_input => DEFAULT_INPUT, :default_output => DEFAULT_OUTPUT),
    :default => "", :attribute_name => :config_string

  option ["-w", "--pipeline-workers"], "COUNT",
         I18n.t("logstash.agent.flag.pipeline-workers"),
         :attribute_name => :pipeline_workers,
         :default => LogStash::Pipeline::DEFAULT_SETTINGS[:default_pipeline_workers]


  option ["-b", "--pipeline-batch-size"], "SIZE",
         I18n.t("logstash.agent.flag.pipeline-batch-size"),
         :attribute_name => :pipeline_batch_size,
         :default => LogStash::Pipeline::DEFAULT_SETTINGS[:pipeline_batch_size]

  option ["-u", "--pipeline-batch-delay"], "DELAY_IN_MS",
         I18n.t("logstash.agent.flag.pipeline-batch-delay"),
         :attribute_name => :pipeline_batch_delay,
         :default => LogStash::Pipeline::DEFAULT_SETTINGS[:pipeline_batch_delay]

  option ["--filterworkers"], "COUNT",
         I18n.t("logstash.agent.flag.filterworkers"),
         :attribute_name => :filter_workers

  option ["-l", "--log"], "FILE",
    I18n.t("logstash.agent.flag.log"),
    :attribute_name => :log_file

  # Old support for the '-v' flag'
  option "-v", :flag,
    I18n.t("logstash.agent.flag.verbosity"),
    :attribute_name => :verbosity, :multivalued => true

  option "--quiet", :flag, I18n.t("logstash.agent.flag.quiet")
  option "--verbose", :flag, I18n.t("logstash.agent.flag.verbose")
  option "--debug", :flag, I18n.t("logstash.agent.flag.debug")

  option ["--debug-config"], :flag,
         I18n.t("logstash.agent.flag.debug_config"),
         :attribute_name => :debug_config, :default => false

  option ["-V", "--version"], :flag,
    I18n.t("logstash.agent.flag.version")

 option ["-p", "--pluginpath"] , "PATH",
   I18n.t("logstash.agent.flag.pluginpath"),
   :multivalued => true,
   :attribute_name => :plugin_paths

  option ["-t", "--configtest"], :flag,
    I18n.t("logstash.agent.flag.configtest"),
    :attribute_name => :config_test

  option "--[no-]allow-unsafe-shutdown", :flag,
    I18n.t("logstash.agent.flag.unsafe_shutdown"),
    :attribute_name => :unsafe_shutdown,
    :default => false

  option ["-r", "--[no-]auto-reload"], :flag,
    I18n.t("logstash.agent.flag.auto_reload"),
    :attribute_name => :auto_reload, :default => false

  option ["--reload-interval"], "RELOAD_INTERVAL",
    I18n.t("logstash.agent.flag.reload_interval"),
    :attribute_name => :reload_interval, :default => 3, &:to_i

  option ["--allow-env"], :flag,
    I18n.t("logstash.agent.flag.allow-env"),
    :attribute_name => :allow_env, :default => false

  def initialize(*params)
    super(*params)
    @logger = Cabin::Channel.get(LogStash)
    @pipelines = {}
    @pipeline_settings ||= { :pipeline_id => "main" }
    @upgrade_mutex = Mutex.new
    @config_loader = LogStash::Config::Loader.new(@logger)
  end

  def pipeline_workers=(pipeline_workers_value)
    @pipeline_settings[:pipeline_workers] = validate_positive_integer(pipeline_workers_value)
  end

  def pipeline_batch_size=(pipeline_batch_size_value)
    @pipeline_settings[:pipeline_batch_size] = validate_positive_integer(pipeline_batch_size_value)
  end

  def pipeline_batch_delay=(pipeline_batch_delay_value)
    @pipeline_settings[:pipeline_batch_delay] = validate_positive_integer(pipeline_batch_delay_value)
  end

  def debug_config=(debug_config)
    @config_loader.debug_config = debug_config
    @debug_config = true
  end

  def validate_positive_integer(str_arg)
    int_arg = str_arg.to_i
    if str_arg !~ /^\d+$/ || int_arg < 1
      raise ArgumentError, "Expected a positive integer, got '#{str_arg}'"
    end

    int_arg
  end

  # Emit a warning message.
  def warn(message)
    # For now, all warnings are fatal.
    raise LogStash::ConfigurationError, message
  end # def warn

  def fail(message)
    raise LogStash::ConfigurationError, message
  end # def fail

  # Run the agent. This method is invoked after clamp parses the
  # flags given to this program.
  def execute
    require "logstash/pipeline"
    require "cabin" # gem 'cabin'
    require "logstash/plugin"

    LogStash::ShutdownWatcher.unsafe_shutdown = unsafe_shutdown?
    LogStash::ShutdownWatcher.logger = @logger

    if version?
      show_version
      return 0
    end

    # temporarily send logs to stdout as well if a --log is specified
    # and stdout appears to be a tty
    show_startup_errors = log_file && STDOUT.tty?

    if show_startup_errors
      stdout_logs = @logger.subscribe(STDOUT)
    end
    configure


    if filter_workers
      @logger.warn("--filter-workers is deprecated! Please use --pipeline-workers or -w. This setting will be removed in the next major version!")
      self.pipeline_workers = filter_workers
    end

    # You must specify a config_string or config_path
    if config_string.nil? && config_path.nil?
      fail(I18n.t("logstash.agent.missing-configuration"))
    end

    if auto_reload? && config_path.nil?
      # there's nothing to reload
      fail(I18n.t("logstash.agent.reload-without-config-path"))
    end

    if config_test?
      config_loader = LogStash::Config::Loader.new(@logger)
      config_str = config_loader.format_config(config_path, config_string)
      begin
        # currently the best strategy to validate the configuration
        # is creating a pipeline instance and checking for exceptions
        LogStash::Pipeline.new(config_str)
        @logger.terminal "Configuration OK"
        return 0
      rescue => e
        @logger.fatal I18n.t("logstash.agent.invalid-configuration", :error => e.message)
        return 1
      end
    end

    register_pipeline("main", @pipeline_settings.merge({
                          :config_string => config_string,
                          :config_path => config_path,
                          :debug_config => debug_config?,
                          :allow_env => allow_env?
                          }))

    sigint_id = trap_sigint()
    sigterm_id = trap_sigterm()
    sighup_id = trap_sighup()

    @logger.unsubscribe(stdout_logs) if show_startup_errors

    @logger.info("starting agent")

    start_pipelines

    return 1 if clean_state?

    @thread = Thread.current # this var is implicilty used by Stud.stop?

    Stud.stoppable_sleep(reload_interval) # sleep before looping

    if auto_reload?
      Stud.interval(reload_interval) { reload_state! }
    else
      while !Stud.stop?
        if clean_state? || running_pipelines?
          sleep 0.5
        else
          break
        end
      end
    end

    shutdown

    return 0
  rescue LogStash::ConfigurationError => e
    @logger.unsubscribe(stdout_logs) if show_startup_errors
    @logger.error I18n.t("logstash.agent.error", :error => e)
    if !config_test?
      @logger.info I18n.t("logstash.agent.configtest-flag-information")
    end
    return 1
  rescue => e
    @logger.unsubscribe(stdout_logs) if show_startup_errors
    @logger.warn(I18n.t("oops"), :error => e, :class => e.class.name, :backtrace => e.backtrace)
    return 1
  ensure
    @log_fd.close if @log_fd
    Stud::untrap("INT", sigint_id) unless sigint_id.nil?
    Stud::untrap("TERM", sigterm_id) unless sigterm_id.nil?
    Stud::untrap("HUP", sighup_id) unless sighup_id.nil?
  end # def execute


  # Do any start-time configuration.
  #
  # Log file stuff, plugin path checking, etc.
  def configure
    configure_logging(log_file)
    configure_plugin_paths(plugin_paths)
  end # def configure

  # Point logging at a specific path.
  def configure_logging(path)
    # Set with the -v (or -vv...) flag
    if quiet?
      @logger.level = :error
    elsif verbose?
      @logger.level = :info
    elsif debug?
      @logger.level = :debug
    else
      # Old support for the -v and -vv stuff.
      if verbosity? && verbosity?.any?
        # this is an array with length of how many times the flag is given
        if verbosity?.length == 1
          @logger.warn("The -v flag is deprecated and will be removed in a future release. You should use --verbose instead.")
          @logger.level = :info
        else
          @logger.warn("The -vv flag is deprecated and will be removed in a future release. You should use --debug instead.")
          @logger.level = :debug
        end
      else
        @logger.level = :warn
      end
    end

    if log_file
      # TODO(sissel): Implement file output/rotation in Cabin.
      # TODO(sissel): Catch exceptions, report sane errors.
      begin
        @log_fd.close if @log_fd
        @log_fd = File.new(path, "a")
      rescue => e
        fail(I18n.t("logstash.agent.configuration.log_file_failed",
                    :path => path, :error => e))
      end

      puts "Sending logstash logs to #{path}."
      @logger.unsubscribe(@logger_subscription) if @logger_subscription
      @logger_subscription = @logger.subscribe(@log_fd)
    else
      @logger.subscribe(STDOUT)
    end

    # TODO(sissel): redirect stdout/stderr to the log as well
    # http://jira.codehaus.org/browse/JRUBY-7003
  end # def configure_logging

  # add the given paths for ungemified/bare plugins lookups
  # @param paths [String, Array<String>] plugins path string or list of path strings to add
  def configure_plugin_paths(paths)
    Array(paths).each do |path|
      fail(I18n.t("logstash.agent.configuration.plugin_path_missing", :path => path)) unless File.directory?(path)
      LogStash::Environment.add_plugin_path(path)
    end
  end

  ## Signal Trapping ##
  def trap_sigint
    Stud::trap("INT") do
      if @interrupted_once
        @logger.fatal(I18n.t("logstash.agent.forced_sigint"))
        exit
      else
        @logger.warn(I18n.t("logstash.agent.sigint"))
        Thread.new(@logger) {|logger| sleep 5; logger.warn(I18n.t("logstash.agent.slow_shutdown")) }
        @interrupted_once = true
        Stud.stop!(@thread)
      end
    end
  end

  def trap_sigterm
    Stud::trap("TERM") do
      @logger.warn(I18n.t("logstash.agent.sigterm"))
      Stud.stop!(@thread)
    end
  end

  def trap_sighup
    Stud::trap("HUP") do
      @logger.warn(I18n.t("logstash.agent.sighup"))
      reload_state!
    end
  end

  ## Pipeline CRUD ##
  def shutdown(pipeline)
    pipeline.shutdown do
      ::LogStash::ShutdownWatcher.start(pipeline)
    end
  end
  #
  # register_pipeline - adds a pipeline to the agent's state
  # @param pipeline_id [String] pipeline string identifier
  # @param settings [Hash] settings that will be passed when creating the pipeline.
  #   keys should be symbols such as :pipeline_workers and :pipeline_batch_delay
  def register_pipeline(pipeline_id, settings)
    pipeline = create_pipeline(settings.merge(:pipeline_id => pipeline_id))
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
          @logger.error(I18n.t("oops"), :error => e, :backtrace => e.backtrace)
        end
      end
    end
  end

  def start_pipelines
    @pipelines.each { |id, _| start_pipeline(id) }
  end

  def shutdown
    shutdown_pipelines
  end

  def shutdown_pipelines
    @pipelines.each { |id, _| stop_pipeline(id) }
  end

  def stop_pipeline(id)
    pipeline = @pipelines[id]
    return unless pipeline
    @logger.log("stopping pipeline", :id => id)
    pipeline.shutdown { LogStash::ShutdownWatcher.start(pipeline) }
    @pipelines[id].thread.join
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

  def clean_state?
    @pipelines.empty?
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
      @logger.log("fetched new config for pipeline. upgrading..",
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

  ## Pipeline Aux methods ##
  def fetch_config(settings)
    @config_loader.format_config(settings[:config_path], settings[:config_string])
  end

  private
  def node_uuid
    @node_uuid ||= SecureRandom.uuid
  end

  ### Version actions ###
  def show_version
    show_version_logstash

    if [:info, :debug].include?(verbosity?) || debug? || verbose?
      show_version_ruby
      show_version_java if LogStash::Environment.jruby?
      show_gems if [:debug].include?(verbosity?) || debug?
    end
  end # def show_version

  def show_version_logstash
    require "logstash/version"
    puts "logstash #{LOGSTASH_VERSION}"
  end # def show_version_logstash

  def show_version_ruby
    puts RUBY_DESCRIPTION
  end # def show_version_ruby

  def show_version_java
    properties = java.lang.System.getProperties
    puts "java #{properties["java.version"]} (#{properties["java.vendor"]})"
    puts "jvm #{properties["java.vm.name"]} / #{properties["java.vm.version"]}"
  end # def show_version_java

  def show_gems
    require "rubygems"
    Gem::Specification.each do |spec|
      puts "gem #{spec.name} #{spec.version}"
    end
  end # def show_gems

end # class LogStash::Agent
