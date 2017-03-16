# encoding: utf-8
Thread.abort_on_exception = true
Encoding.default_external = Encoding::UTF_8
$DEBUGLIST = (ENV["DEBUG"] || "").split(",")

require "clamp"
require "net/http"

require "logstash/namespace"
require "logstash-core/logstash-core"
require "logstash/environment"

LogStash::Environment.load_locale!

require "logstash/agent"
require "logstash/config/defaults"
require "logstash/shutdown_watcher"
require "logstash/patches/clamp"
require "logstash/settings"
require "logstash/version"
require "logstash/plugins/registry"
require "logstash/bootstrap_check/default_config"
require "logstash/bootstrap_check/bad_java"
require "logstash/bootstrap_check/bad_ruby"
require "set"

java_import 'org.logstash.FileLockFactory'

class LogStash::Runner < Clamp::StrictCommand
  include LogStash::Util::Loggable
  # The `path.settings` and `path.logs` need to be defined in the runner instead of the `logstash-core/lib/logstash/environment.rb`
  # because the `Environment::LOGSTASH_HOME` doesn't exist in the context of the `logstash-core` gem.
  #
  # See issue https://github.com/elastic/logstash/issues/5361
  LogStash::SETTINGS.register(LogStash::Setting::String.new("path.settings", ::File.join(LogStash::Environment::LOGSTASH_HOME, "config")))
  LogStash::SETTINGS.register(LogStash::Setting::String.new("path.logs", ::File.join(LogStash::Environment::LOGSTASH_HOME, "logs")))

  # Ordered list of check to run before starting logstash
  # theses checks can be changed by a plugin loaded into memory.
  DEFAULT_BOOTSTRAP_CHECKS = [
      LogStash::BootstrapCheck::BadRuby,
      LogStash::BootstrapCheck::BadJava,
      LogStash::BootstrapCheck::DefaultConfig
  ]

  # Node Settings
  option ["-n", "--node.name"], "NAME",
    I18n.t("logstash.runner.flag.name"),
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
  option ["-l", "--path.logs"], "PATH",
    I18n.t("logstash.runner.flag.log"),
    :attribute_name => "path.logs",
    :default => LogStash::SETTINGS.get_default("path.logs")

  option "--log.level", "LEVEL", I18n.t("logstash.runner.flag.log_level"),
    :default => LogStash::SETTINGS.get_default("log.level"),
    :attribute_name => "log.level"

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

  ### DEPRECATED FLAGS ###
  deprecated_option ["--verbose"], :flag,
    I18n.t("logstash.runner.flag.verbose"),
    :new_flag => "log.level", :new_value => "info"

  deprecated_option ["--debug"], :flag,
    I18n.t("logstash.runner.flag.debug"),
    :new_flag => "log.level", :new_value => "debug"

  deprecated_option ["--quiet"], :flag,
    I18n.t("logstash.runner.flag.quiet"),
    :new_flag => "log.level", :new_value => "error"

  attr_reader :agent, :settings, :source_loader
  attr_accessor :bootstrap_checks

  def initialize(*args)
    @settings = LogStash::SETTINGS
    @bootstrap_checks = DEFAULT_BOOTSTRAP_CHECKS.dup

    # Default we check local sources: `-e`, `-f` and the logstash.yml options.
    @source_loader = LogStash::Config::SourceLoader.new(@settings)
    @source_loader.add_source(LogStash::Config::Source::Local.new(@settings))
    @source_loader.add_source(LogStash::Config::Source::MultiLocal.new(@settings))

    super(*args)
  end

  def run(args)
    settings_path = fetch_settings_path(args)

    @settings.set("path.settings", settings_path) if settings_path

    begin
      LogStash::SETTINGS.from_yaml(LogStash::SETTINGS.get("path.settings"))
    rescue Errno::ENOENT
      $stderr.puts "WARNING: Could not find logstash.yml which is typically located in $LS_HOME/config or /etc/logstash. You can specify the path using --path.settings. Continuing using the defaults"
    rescue => e
      # abort unless we're just looking for the help
      unless cli_help?(args)
        if e.kind_of?(Psych::Exception)
          yaml_file_path = ::File.join(LogStash::SETTINGS.get("path.settings"), "logstash.yml")
          $stderr.puts "ERROR: Failed to parse YAML file \"#{yaml_file_path}\". Please confirm if the YAML structure is valid (e.g. look for incorrect usage of whitespace or indentation). Aborting... parser_error=>#{e.message}"
        else
          $stderr.puts "ERROR: Failed to load settings file from \"path.settings\". Aborting... path.setting=#{LogStash::SETTINGS.get("path.settings")}, exception=#{e.class}, message=>#{e.message}"
        end
        return 1
      end
    end

    super(*[args])
  end

  def execute
    # Only when execute is have the CLI options been added to the @settings
    # We invoke post_process to apply extra logic to them.
    # The post_process callbacks have been added in environment.rb
    @settings.post_process

    require "logstash/util"
    require "logstash/util/java_version"
    require "stud/task"

    # Configure Logstash logging facility, this need to be done before everything else to
    # make sure the logger has the correct settings and the log level is correctly defined.
    java.lang.System.setProperty("ls.logs", setting("path.logs"))
    java.lang.System.setProperty("ls.log.format", setting("log.format"))
    java.lang.System.setProperty("ls.log.level", setting("log.level"))
    unless java.lang.System.getProperty("log4j.configurationFile")
      log4j_config_location = ::File.join(setting("path.settings"), "log4j2.properties")
      LogStash::Logging::Logger::initialize("file:///" + log4j_config_location)
    end
    # override log level that may have been introduced from a custom log4j config file
    LogStash::Logging::Logger::configure_logging(setting("log.level"))

    if setting("config.debug") && !logger.debug?
      logger.warn("--config.debug was specified, but log.level was not set to \'debug\'! No config info will be logged.")
    end

    # Skip any validation and just return the version
    if version?
      show_version
      return 0
    end

    # We configure the registry and load any plugin that can register hooks
    # with logstash, this need to be done before any operation.
    LogStash::PLUGIN_REGISTRY.setup!

    @dispatcher = LogStash::EventDispatcher.new(self)
    LogStash::PLUGIN_REGISTRY.hooks.register_emitter(self.class, @dispatcher)

    @settings.validate_all
    @dispatcher.fire(:before_bootstrap_checks)

    return start_shell(setting("interactive"), binding) if setting("interactive")

    begin
      @bootstrap_checks.each { |bootstrap| bootstrap.check(@settings) }
    rescue LogStash::BootstrapCheckError => e
      signal_usage_error(e.message)
      return 1
    end
    @dispatcher.fire(:after_bootstrap_checks)

    LogStash::Util::set_thread_name(self.class.name)

    LogStash::ShutdownWatcher.unsafe_shutdown = setting("pipeline.unsafe_shutdown")

    configure_plugin_paths(setting("path.plugins"))


    @settings.format_settings.each {|line| logger.debug(line) }

    if setting("config.test_and_exit")
      begin
        results = @source_loader.fetch

        # TODO(ph): make it better for multiple pipeline
        if results.success?
          results.response.each do |pipeline_config|
            LogStash::BasePipeline.new(pipeline_config)
          end
          puts "Configuration OK"
          logger.info "Using config.test_and_exit mode. Config Validation Result: OK. Exiting Logstash"
        else
          raise "Could not load the configuration file"
        end
        return 0
      rescue => e
        logger.fatal I18n.t("logstash.runner.invalid-configuration", :error => e.message)
        return 1
      end
    end

    # lock path.data before starting the agent
    @data_path_lock = FileLockFactory.getDefault().obtainLock(setting("path.data"), ".lock");

    @dispatcher.fire(:before_agent)
    @agent = create_agent(@settings, @source_loader)
    @dispatcher.fire(:after_agent)

    # enable sigint/sigterm before starting the agent
    # to properly handle a stalled agent
    sigint_id = trap_sigint()
    sigterm_id = trap_sigterm()

    @agent_task = Stud::Task.new { @agent.execute }

    # no point in enabling config reloading before the agent starts
    # also windows doesn't have SIGHUP. we can skip it
    sighup_id = LogStash::Environment.windows? ? nil : trap_sighup()

    agent_return = @agent_task.wait

    @agent.shutdown

    # flush any outstanding log messages during shutdown
    org.apache.logging.log4j.LogManager.shutdown

    agent_return

  rescue org.logstash.LockException => e
    logger.fatal(I18n.t("logstash.runner.locked-data-path", :path => setting("path.data")))
    return 1
  rescue Clamp::UsageError => e
    $stderr.puts "ERROR: #{e.message}"
    show_short_help
    return 1
  rescue => e
    # if logger itself is not initialized
    if LogStash::Logging::Logger.get_logging_context.nil?
      $stderr.puts "#{I18n.t("oops")} :error => #{e}, :backtrace => #{e.backtrace}"
    else
      logger.fatal(I18n.t("oops"), :error => e, :backtrace => e.backtrace)
    end
    return 1
  ensure
    Stud::untrap("INT", sigint_id) unless sigint_id.nil?
    Stud::untrap("TERM", sigterm_id) unless sigterm_id.nil?
    Stud::untrap("HUP", sighup_id) unless sighup_id.nil?
    FileLockFactory.getDefault().releaseLock(@data_path_lock) if @data_path_lock
    @log_fd.close if @log_fd
  end # def self.main

  def show_version
    show_version_logstash

    if logger.info?
      show_version_ruby
      show_version_java if LogStash::Environment.jruby?
      show_gems if logger.debug?
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
      logger.warn(I18n.t("logstash.agent.sighup"))
      @agent.converge_state_and_update
    end
  end

  def trap_sigterm
    Stud::trap("TERM") do
      logger.warn(I18n.t("logstash.agent.sigterm"))
      @agent_task.stop!
    end
  end

  def trap_sigint
    Stud::trap("INT") do
      if @interrupted_once
        logger.fatal(I18n.t("logstash.agent.forced_sigint"))
        @agent.force_shutdown!
        exit
      else
        logger.warn(I18n.t("logstash.agent.sigint"))
        Thread.new(logger) {|lg| sleep 5; lg.warn(I18n.t("logstash.agent.slow_shutdown")) }
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
  
  # is the user asking for CLI help subcommand?
  def cli_help?(args)
    # I know, double negative
    !(["--help", "-h"] & args).empty?
  end

end
