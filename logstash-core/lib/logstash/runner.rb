# encoding: utf-8
Thread.abort_on_exception = true
Encoding.default_external = Encoding::UTF_8
$DEBUGLIST = (ENV["DEBUG"] || "").split(",")

require "clamp"
require "cabin"
require "net/http"
require "logstash/environment"

LogStash::Environment.load_locale!

require "logstash/namespace"
require "logstash/agent"
require "logstash/config/defaults"
require "logstash/shutdown_watcher"
require "logstash/patches/clamp"
require "logstash/settings"
require "logstash/version"

class LogStash::Runner < Clamp::StrictCommand
  # The `path.settings` need to be defined in the runner instead of the `logstash-core/lib/logstash/environment.rb`
  # because the `Environment::LOGSTASH_HOME` doesn't exist in the context of the `logstash-core` gem.
  # 
  # See issue https://github.com/elastic/logstash/issues/5361
  LogStash::SETTINGS.register(LogStash::Setting::String.new("path.settings", ::File.join(LogStash::Environment::LOGSTASH_HOME, "config")))

  # Node Settings
  option ["-n", "--node.name"], "NAME",
    I18n.t("logstash.runner.flag.node_name"),
    :attribute_name => "node.name",
    :default => LogStash::SETTINGS.get_default("node.name")

  # Config Settings
  option ["-f", "--path.config"], "CONFIG_PATH",
    I18n.t("logstash.runner.flag.config"),
    :attribute_name => "path.config"

  option ["-e", "--config.string"], "CONFIG_STRING",
    I18n.t("logstash.runner.flag.config-string",
      :default_input => LogStash::Config::Defaults.input,
      :default_output => LogStash::Config::Defaults.output),
    :default => LogStash::SETTINGS.get_default("config.string"),
    :attribute_name => "config.string"

  # Pipeline settings
  option ["-w", "--pipeline.workers"], "COUNT",
    I18n.t("logstash.runner.flag.pipeline-workers"),
    :attribute_name => "pipeline.workers",
    :default => LogStash::SETTINGS.get_default("pipeline.workers")

  option ["-b", "--pipeline.batch.size"], "SIZE",
    I18n.t("logstash.runner.flag.pipeline-batch-size"),
    :attribute_name => "pipeline.batch.size",
    :default => LogStash::SETTINGS.get_default("pipeline.batch.size")

  option ["-u", "--pipeline.batch.delay"], "DELAY_IN_MS",
    I18n.t("logstash.runner.flag.pipeline-batch-delay"),
    :attribute_name => "pipeline.batch.delay",
    :default => LogStash::SETTINGS.get_default("pipeline.batch.delay")

  option ["--pipeline.unsafe_shutdown"], :flag,
    I18n.t("logstash.runner.flag.unsafe_shutdown"),
    :attribute_name => "pipeline.unsafe_shutdown",
    :default => LogStash::SETTINGS.get_default("pipeline.unsafe_shutdown")

  # Data Path Setting
  option ["--path.data"] , "PATH",
    I18n.t("logstash.runner.flag.datapath"),
    :attribute_name => "path.data",
    :default => LogStash::SETTINGS.get_default("path.data")

  # Plugins Settings
  option ["-p", "--path.plugins"] , "PATH",
    I18n.t("logstash.runner.flag.pluginpath"),
    :multivalued => true, :attribute_name => "path.plugins",
    :default => LogStash::SETTINGS.get_default("path.plugins")

  # Logging Settings
  option ["-l", "--path.log"], "FILE",
    I18n.t("logstash.runner.flag.log"),
    :attribute_name => "path.log"

  option "--log.level", "LEVEL", I18n.t("logstash.runner.flag.log_level"),
    :default => LogStash::SETTINGS.get_default("log.level")

  option "--config.debug", :flag,
    I18n.t("logstash.runner.flag.config_debug"),
    :default => LogStash::SETTINGS.get_default("config.debug"),
    :attribute_name => "config.debug"

  # Other settings
  option ["-i", "--interactive"], "SHELL",
    I18n.t("logstash.runner.flag.rubyshell"),
    :attribute_name => "interactive"

  option ["-V", "--version"], :flag,
    I18n.t("logstash.runner.flag.version")

  option ["-t", "--config.test_and_exit"], :flag,
    I18n.t("logstash.runner.flag.configtest"),
    :attribute_name => "config.test_and_exit",
    :default => LogStash::SETTINGS.get_default("config.test_and_exit")

  option ["-r", "--config.reload.automatic"], :flag,
    I18n.t("logstash.runner.flag.auto_reload"),
    :attribute_name => "config.reload.automatic",
    :default => LogStash::SETTINGS.get_default("config.reload.automatic")

  option ["--config.reload.interval"], "RELOAD_INTERVAL",
    I18n.t("logstash.runner.flag.reload_interval"),
    :attribute_name => "config.reload.interval",
    :default => LogStash::SETTINGS.get_default("config.reload.interval")

  option ["--http.host"], "HTTP_HOST",
    I18n.t("logstash.runner.flag.http_host"),
    :attribute_name => "http.host",
    :default => LogStash::SETTINGS.get_default("http.host")

  option ["--http.port"], "HTTP_PORT",
    I18n.t("logstash.runner.flag.http_port"),
    :attribute_name => "http.port",
    :default => LogStash::SETTINGS.get_default("http.port")

  option ["--log.format"], "FORMAT",
    I18n.t("logstash.runner.flag.log_format"),
    :attribute_name => "log.format",
    :default => LogStash::SETTINGS.get_default("log.format")

  option ["--path.settings"], "SETTINGS_DIR",
    I18n.t("logstash.runner.flag.path_settings"),
    :attribute_name => "path.settings",
    :default => LogStash::SETTINGS.get_default("path.settings")

  attr_reader :agent

  def initialize(*args)
    @logger = Cabin::Channel.get(LogStash)
    @settings = LogStash::SETTINGS
    super(*args)
  end

  def run(args)
    settings_path = fetch_settings_path(args)

    @settings.set("path.settings", settings_path) if settings_path

    begin
      LogStash::SETTINGS.from_yaml(LogStash::SETTINGS.get("path.settings"))
    rescue => e
      # abort unless we're just looking for the help
      if (["--help", "-h"] & args).empty?
        @logger.subscribe(STDOUT)
        @logger.warn("Logstash has a new settings file which defines start up time settings. This file is typically located in $LS_HOME/config or /etc/logstash. If you installed Logstash through a package and are starting it manually please specify the location to this settings file by passing in \"--path.settings=/path/..\" in the command line options")
        @logger.fatal("Failed to load settings file from \"path.settings\". Aborting...", "path.settings" => LogStash::SETTINGS.get("path.settings"), "exception" => e.class, "message" => e.message)
        return 1
      end
    end

    super(*[args])
  end

  def execute
    require "logstash/util"
    require "logstash/util/java_version"
    require "stud/task"
    require "cabin" # gem 'cabin'
    require "logstash/logging/json"

    # Configure Logstash logging facility, this need to be done before everything else to
    # make sure the logger has the correct settings and the log level is correctly defined.
    configure_logging(setting("path.log"), setting("log.level"))

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

    LogStash::ShutdownWatcher.unsafe_shutdown = setting("pipeline.unsafe_shutdown")
    LogStash::ShutdownWatcher.logger = @logger

    configure_plugin_paths(setting("path.plugins"))

    if version?
      show_version
      return 0
    end

    return start_shell(setting("interactive"), binding) if setting("interactive")

    @settings.format_settings.each {|line| @logger.info(line) }

    if setting("config.string").nil? && setting("path.config").nil?
      fail(I18n.t("logstash.runner.missing-configuration"))
    end

    if setting("config.reload.automatic") && setting("path.config").nil?
      # there's nothing to reload
      signal_usage_error(I18n.t("logstash.runner.reload-without-config-path"))
    end

    if setting("config.test_and_exit")
      config_loader = LogStash::Config::Loader.new(@logger)
      config_str = config_loader.format_config(setting("path.config"), setting("config.string"))
      begin
        LogStash::Pipeline.new(config_str)
        @logger.terminal "Configuration OK"
        return 0
      rescue => e
        @logger.fatal I18n.t("logstash.runner.invalid-configuration", :error => e.message)
        return 1
      end
    end

    @agent = create_agent(@settings)

    @agent.register_pipeline("main", @settings)

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

    if @logger.debug? || @logger.info?
      show_version_ruby
      show_version_java if LogStash::Environment.jruby?
      show_gems if @logger.debug?
    end
  end # def show_version

  def show_version_logstash
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
  def configure_logging(path, level)
    @logger = Cabin::Channel.get(LogStash)
    # Set with the -v (or -vv...) flag
    case level
    when "quiet"
      @logger.level = :error
    when "verbose"
      @logger.level = :info
    when "debug"
      @logger.level = :debug
    else
      @logger.level = :warn
    end

    if path
      # TODO(sissel): Implement file output/rotation in Cabin.
      # TODO(sissel): Catch exceptions, report sane errors.
      begin
        @log_fd.close if @log_fd
        @log_fd = File.new(path, "a")
      rescue => e
        fail(I18n.t("logstash.runner.configuration.log_file_failed",
                    :path => path, :error => e))
      end

      if setting("log.format") == "json"
        @logger.subscribe(LogStash::Logging::JSON.new(STDOUT), :level => :fatal)
        @logger.subscribe(LogStash::Logging::JSON.new(@log_fd))
      else
        @logger.subscribe(STDOUT, :level => :fatal)
        @logger.subscribe(@log_fd)
      end
      @logger.terminal "Sending logstash logs to #{path}."
    else
      if setting("log.format") == "json"
        @logger.subscribe(LogStash::Logging::JSON.new(STDOUT))
      else
        @logger.subscribe(STDOUT)
      end
    end

    if setting("config.debug") && @logger.level != :debug
      @logger.warn("--config.debug was specified, but log.level was not set to \'debug\'! No config info will be logged.")
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

  def setting(key)
    @settings.get_value(key)
  end

  # where can I find the logstash.yml file?
  # 1. look for a "--path.settings path"
  # 2. look for a "--path.settings=path"
  # 3. check if the LS_SETTINGS_DIR environment variable is set
  # 4. return nil if not found
  def fetch_settings_path(cli_args)
    if i=cli_args.find_index("--path.settings")
      cli_args[i+1]
    elsif settings_arg = cli_args.find {|v| v.match(/--path.settings=/) }
      match = settings_arg.match(/--path.settings=(.*)/)
      match[1]
    elsif ENV['LS_SETTINGS_DIR']
      ENV['LS_SETTINGS_DIR']
    else
      nil
    end
  end

end
