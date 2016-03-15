# encoding: utf-8
Thread.abort_on_exception = true
Encoding.default_external = Encoding::UTF_8
$DEBUGLIST = (ENV["DEBUG"] || "").split(",")

require "clamp" # gem 'clamp'
require "net/http"
require "logstash/environment"

LogStash::Environment.load_locale!

require "logstash/namespace"
require "logstash/agent"
require "logstash/config/defaults"

class LogStash::Runner < Clamp::Command

  option ["-f", "--config"], "CONFIG_PATH",
    I18n.t("logstash.runner.flag.config"),
    :attribute_name => :config_path

  option "-e", "CONFIG_STRING",
    I18n.t("logstash.runner.flag.config-string",
           :default_input => LogStash::Config::Defaults.input,
           :default_output => LogStash::Config::Defaults.output),
    :default => nil, :attribute_name => :config_string

  option ["-w", "--pipeline-workers"], "COUNT",
    I18n.t("logstash.runner.flag.pipeline-workers"),
    :attribute_name => :pipeline_workers,
    :default => LogStash::Pipeline::DEFAULT_SETTINGS[:default_pipeline_workers]

  option ["-b", "--pipeline-batch-size"], "SIZE",
         I18n.t("logstash.runner.flag.pipeline-batch-size"),
         :attribute_name => :pipeline_batch_size,
         :default => LogStash::Pipeline::DEFAULT_SETTINGS[:pipeline_batch_size]

  option ["-u", "--pipeline-batch-delay"], "DELAY_IN_MS",
         I18n.t("logstash.runner.flag.pipeline-batch-delay"),
         :attribute_name => :pipeline_batch_delay,
         :default => LogStash::Pipeline::DEFAULT_SETTINGS[:pipeline_batch_delay]

  option ["-l", "--log"], "FILE",
    I18n.t("logstash.runner.flag.log"),
    :attribute_name => :log_file

  # Old support for the '-v' flag'
  option "-v", :flag,
    I18n.t("logstash.runner.flag.verbosity"),
    :attribute_name => :verbosity, :multivalued => true

  option "--quiet", :flag, I18n.t("logstash.runner.flag.quiet")
  option "--verbose", :flag, I18n.t("logstash.runner.flag.verbose")
  option "--debug", :flag, I18n.t("logstash.runner.flag.debug")

  option ["--debug-config"], :flag,
         I18n.t("logstash.runner.flag.debug_config"),
         :attribute_name => :debug_config, :default => false

  option ["-V", "--version"], :flag,
    I18n.t("logstash.runner.flag.version")

  option ["-p", "--pluginpath"] , "PATH",
    I18n.t("logstash.runner.flag.pluginpath"),
    :multivalued => true,
    :attribute_name => :plugin_paths

  option ["-t", "--configtest"], :flag,
    I18n.t("logstash.runner.flag.configtest"),
    :attribute_name => :config_test

  option "--[no-]allow-unsafe-shutdown", :flag,
    I18n.t("logstash.runner.flag.unsafe_shutdown"),
    :attribute_name => :unsafe_shutdown,
    :default => false

  option ["-i", "--interactive"], "SHELL",
    I18n.t("logstash.runner.flag.rubyshell"),
    :attribute_name => :ruby_shell

  option ["-n", "--node-name"], "NAME",
    I18n.t("logstash.runner.flag.node_name"),
    :attribute_name => :node_name

  option ["-r", "--[no-]auto-reload"], :flag,
    I18n.t("logstash.runner.flag.auto_reload"),
    :attribute_name => :auto_reload, :default => false

  option ["--reload-interval"], "RELOAD_INTERVAL",
    I18n.t("logstash.runner.flag.reload_interval"),
    :attribute_name => :reload_interval, :default => 3, &:to_i

  option ["--http-host"], "WEB_API_HTTP_HOST",
    I18n.t("logstash.web_api.flag.http_host"),
    :attribute_name => :web_api_http_host, :default => "127.0.0.1"

  option ["--http-port"], "WEB_API_HTTP_PORT",
    I18n.t("logstash.web_api.flag.http_port"),
    :attribute_name => :web_api_http_port, :default => 9600

  option ["--allow-env"], :flag,
    I18n.t("logstash.runner.flag.allow-env"),
    :attribute_name => :allow_env, :default => false

  option ["--[no-]log-in-json"], :flag,
    I18n.t("logstash.runner.flag.log-in-json"),
    :default => false

  def pipeline_workers=(pipeline_workers_value)
    @pipeline_settings[:pipeline_workers] = validate_positive_integer(pipeline_workers_value)
  end

  def pipeline_batch_size=(pipeline_batch_size_value)
    @pipeline_settings[:pipeline_batch_size] = validate_positive_integer(pipeline_batch_size_value)
  end

  def pipeline_batch_delay=(pipeline_batch_delay_value)
    @pipeline_settings[:pipeline_batch_delay] = validate_positive_integer(pipeline_batch_delay_value)
  end

  def validate_positive_integer(str_arg)
    int_arg = str_arg.to_i
    if str_arg !~ /^\d+$/ || int_arg < 1
      raise ArgumentError, "Expected a positive integer, got '#{str_arg}'"
    end

    int_arg
  end

  attr_reader :agent

  def initialize(*args)
    @logger = Cabin::Channel.get(LogStash)
    @pipeline_settings ||= { :pipeline_id => "main" }
    super(*args)
  end

  def execute
    require "logstash/util"
    require "logstash/util/java_version"
    require "stud/task"
    require "cabin" # gem 'cabin'
    require "logstash/logging/json"

    # Configure Logstash logging facility, this need to be done before everything else to
    # make sure the logger has the correct settings and the log level is correctly defined.
    configure_logging(log_file)

    LogStash::Util::set_thread_name(self.class.name)

    if RUBY_VERSION < "1.9.2"
      $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
      return 1
    end

    # Exit on bad java versions
    java_version = LogStash::Util::JavaVersion.version
    if LogStash::Util::JavaVersion.bad_java_version?(java_version)
      $stderr.puts "Java version 1.8.0 or later is required. (You are running: #{java_version})"
      return 1
    end  

    LogStash::ShutdownWatcher.unsafe_shutdown = unsafe_shutdown?
    LogStash::ShutdownWatcher.logger = @logger

    configure

    if version?
      show_version
      return 0
    end

    return start_shell(@ruby_shell, binding) if @ruby_shell

    if config_string.nil? && config_path.nil?
      fail(I18n.t("logstash.runner.missing-configuration"))
    end

    if @auto_reload && config_path.nil?
      # there's nothing to reload
      signal_usage_error(I18n.t("logstash.runner.reload-without-config-path"))
    end

    if config_test?
      config_loader = LogStash::Config::Loader.new(@logger, @debug_config)
      config_str = config_loader.format_config(config_path, config_string)
      begin
        LogStash::Pipeline.new(config_str)
        @logger.terminal "Configuration OK"
        return 0
      rescue => e
        @logger.fatal I18n.t("logstash.runner.invalid-configuration", :error => e.message)
        return 1
      end
    end

    @agent = create_agent(:logger => @logger,
                          :auto_reload => @auto_reload,
                          :reload_interval => @reload_interval,
                          :collect_metric => true,
                          :debug => debug?,
                          :node_name => node_name,
                          :debug_config => debug_config?,
                          :web_api_http_host => @web_api_http_host,
                          :web_api_http_port => @web_api_http_port)

    @agent.register_pipeline("main", @pipeline_settings.merge({
                          :config_string => config_string,
                          :config_path => config_path,
                          :debug_config => debug_config?,
                          :allow_env => allow_env?
                          }))

    # enable sigint/sigterm before starting the agent
    # to properly handle a stalled agent
    sigint_id = trap_sigint()
    sigterm_id = trap_sigterm()

    @agent_task = Stud::Task.new { @agent.execute }

    # no point in enabling config reloading before the agent starts
    sighup_id = trap_sighup()

    agent_return = @agent_task.wait

    @agent.shutdown

    agent_return

  rescue Clamp::UsageError => e
    $stderr.puts "ERROR: #{e.message}"
    show_short_help
    return 1
  rescue => e
    @logger.fatal(I18n.t("oops"), :error => e, :backtrace => e.backtrace)
    return 1
  ensure
    Stud::untrap("INT", sigint_id) unless sigint_id.nil?
    Stud::untrap("TERM", sigterm_id) unless sigterm_id.nil?
    Stud::untrap("HUP", sighup_id) unless sighup_id.nil?
    @log_fd.close if @log_fd
  end # def self.main

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

  # Do any start-time configuration.
  #
  # Log file stuff, plugin path checking, etc.
  def configure
    configure_plugin_paths(plugin_paths)
  end # def configure

  # add the given paths for ungemified/bare plugins lookups
  # @param paths [String, Array<String>] plugins path string or list of path strings to add
  def configure_plugin_paths(paths)
    Array(paths).each do |path|
      fail(I18n.t("logstash.runner.configuration.plugin_path_missing", :path => path)) unless File.directory?(path)
      LogStash::Environment.add_plugin_path(path)
    end
  end

  def create_agent(*args)
    LogStash::Agent.new(*args)
  end

  # Point logging at a specific path.
  def configure_logging(path)
    @logger = Cabin::Channel.get(LogStash)
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
        fail(I18n.t("logstash.runner.configuration.log_file_failed",
                    :path => path, :error => e))
      end

      if log_in_json?
        @logger.subscribe(LogStash::Logging::JSON.new(STDOUT), :level => :fatal)
        @logger.subscribe(LogStash::Logging::JSON.new(@log_fd))
      else
        @logger.subscribe(STDOUT, :level => :fatal)
        @logger.subscribe(@log_fd)
      end
      @logger.terminal "Sending logstash logs to #{path}."
    else
      if log_in_json?
        @logger.subscribe(LogStash::Logging::JSON.new(STDOUT))
      else
        @logger.subscribe(STDOUT)
      end
    end

    if debug_config? && @logger.level != :debug
      @logger.warn("--debug-config was specified, but log level was not set to --debug! No config info will be logged.")
    end

    # TODO(sissel): redirect stdout/stderr to the log as well
    # http://jira.codehaus.org/browse/JRUBY-7003
  end # def configure_logging

  # Emit a failure message and abort.
  def fail(message)
    signal_usage_error(message)
  end # def fail

  def show_short_help
    puts I18n.t("logstash.runner.short-help")
  end

  def start_shell(shell, start_binding)
    case shell
    when "pry"
      require 'pry'
      start_binding.pry
    when "irb"
      require 'irb'
      ARGV.clear
      # TODO: set binding to this instance of Runner
      # currently bugged as per https://github.com/jruby/jruby/issues/384
      IRB.start(__FILE__)
    else
      fail(I18n.t("logstash.runner.invalid-shell"))
    end
  end

  def trap_sighup
    Stud::trap("HUP") do
      @logger.warn(I18n.t("logstash.agent.sighup"))
      @agent.reload_state!
    end
  end

  def trap_sigterm
    Stud::trap("TERM") do
      @logger.warn(I18n.t("logstash.agent.sigterm"))
      @agent_task.stop!
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
        @agent_task.stop!
      end
    end
  end

end # class LogStash::Runner
