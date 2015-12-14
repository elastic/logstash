# encoding: utf-8
Thread.abort_on_exception = true
Encoding.default_external = Encoding::UTF_8
$DEBUGLIST = (ENV["DEBUG"] || "").split(",")

require "clamp" # gem 'clamp'
require "net/http"
require "logstash/environment"

LogStash::Environment.load_locale!

require "logstash/namespace"
require "logstash/agent_plugin_registry"
require "logstash/agent"
require "logstash/config/defaults"

class LogStash::Runner < Clamp::Command
  class MissingAgentError < StandardError; end # Raised when the user asks for an agent plugin that doesn't exist

  option ["-f", "--config"], "CONFIG_PATH",
    I18n.t("logstash.runner.flag.config"),
    :attribute_name => :config_path

  option "-e", "CONFIG_STRING",
    I18n.t("logstash.runner.flag.config-string",
           :default_input => LogStash::Config::Defaults.input,
           :default_output => LogStash::Config::Defaults.output),
    :default => nil, :attribute_name => :config_string

  option ["-w", "--filterworkers"], "COUNT",
    I18n.t("logstash.runner.flag.filterworkers"),
    :attribute_name => :filter_workers,
    :default => LogStash::Config::CpuCoreStrategy.fifty_percent, &:to_i

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
    I18n.t("logstash.agent.flag.unsafe_shutdown"),
    :attribute_name => :unsafe_shutdown,
    :default => false

  option ["-i", "--interactive"], "SHELL",
    I18n.t("logstash.runner.flag.rubyshell"),
    :attribute_name => :ruby_shell

  option ["-a", "--agent"], "AGENT",
    I18n.t("logstash.runner.flag.agent"),
    :attribute_name => :agent_name, :default => LogStash::AgentPluginRegistry::DEFAULT_AGENT_NAME

  option ["-r", "--[no-]auto-reload"], :flag,
    I18n.t("logstash.runner.flag.auto_reload"),
    :attribute_name => :auto_reload, :default => false

  attr_reader :agent

  def initialize(*args)
    LogStash::AgentPluginRegistry.load_all
    @logger = Cabin::Channel.get(LogStash)
    super(*args)
  end

  def execute
    require "logstash/util"
    require "logstash/util/java_version"
    require "stud/task"
    require "cabin" # gem 'cabin'

    LogStash::Util::set_thread_name(self.class.name)

    if RUBY_VERSION < "1.9.2"
      $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
      return 1
    end

    # Print a warning to STDERR for bad java versions
    LogStash::Util::JavaVersion.warn_on_bad_java_version

    LogStash::ShutdownController.unsafe_shutdown = unsafe_shutdown?
    LogStash::ShutdownController.logger = @logger

    configure

    if version?
      show_version
      return 0
    end

    return start_shell(@ruby_shell, binding) if @ruby_shell

    if config_string.nil? && config_path.nil?
      fail(I18n.t("logstash.runner.missing-configuration"))
    end

    if config_test?
      config_loader = LogStash::Config::Loader.new(@logger, config_test?)
      config_str = config_loader.format_config(config_path, config_string)
      config_error = LogStash::Pipeline.config_valid?(config_str)
      if config_error == true
        @logger.terminal "Configuration OK"
        return 0
      else
        @logger.fatal I18n.t("logstash.error", :error => config_error)
        return 1
      end
    end

    @agent = create_agent(:logger => @logger,
                          :config_string => config_string,
                          :config_path => config_path,
                          :auto_reload => @auto_reload)

    # enable sigint/sigterm before starting the agent
    # to properly handle a stalled agent
    sigint_id = trap_sigint()
    sigterm_id = trap_sigterm()

    @agent_task = Stud::Task.new { @agent.execute }

    # no point in enabling config reloading before the agent starts
    sighup_id = trap_sighup()

    @agent_task.wait

    @agent.shutdown

  rescue LoadError => e
    fail("Configuration problem.")
  rescue LogStash::ConfigurationError => e
    @logger.warn I18n.t("logstash.runner.configtest-flag-information")
    @logger.fatal I18n.t("logstash.error", :error => e)
    show_short_help
    return 1
  rescue MissingAgentError => e
    @logger.fatal("Could not load specified agent",
                  :agent_name => agent_name,
                  :valid_agent_names => LogStash::AgentPluginRegistry.available.map(&:to_s))
    return 1
  rescue => e
    @logger.fatal I18n.t("oops", :error => e)
    @logger.debug e.backtrace if $DEBUGLIST.include?("stacktrace")
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
    configure_logging(log_file)
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
    agent_class = LogStash::AgentPluginRegistry.lookup(agent_name)
    @logger.info("Creating new agent", :class => agent_class)
    agent_class.new(*args)
  end

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
        fail(I18n.t("logstash.runner.configuration.log_file_failed",
                    :path => path, :error => e))
      end

      @logger.subscribe(STDOUT, :level => :fatal)
      @logger.subscribe(@log_fd)
      @logger.terminal "Sending logstash logs to #{path}."
    else
      @logger.subscribe(STDOUT)
    end

    # TODO(sissel): redirect stdout/stderr to the log as well
    # http://jira.codehaus.org/browse/JRUBY-7003
  end # def configure_logging

  # Emit a failure message and abort.
  def fail(message)
    raise LogStash::ConfigurationError, message
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
      @agent.reload_state
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
