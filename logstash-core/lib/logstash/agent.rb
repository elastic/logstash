# encoding: utf-8
require "clamp" # gem 'clamp'
require "logstash/environment"
require "logstash/errors"
require "logstash/config/cpu_core_strategy"
require "uri"
require "net/http"
require "logstash/pipeline"
LogStash::Environment.load_locale!

class LogStash::Agent < Clamp::Command
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

  def initialize(*args)
    super(*args)
    @pipeline_settings ||= { :pipeline_id => "base" }
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

  # Emit a failure message and abort.
  def fail(message)
    raise LogStash::ConfigurationError, message
  end # def fail

  def report(message)
    # Print to stdout just in case we're logging to a file
    puts message
    @logger.log(message) if log_file
  end

  # Run the agent. This method is invoked after clamp parses the
  # flags given to this program.
  def execute
    require "logstash/pipeline"
    require "cabin" # gem 'cabin'
    require "logstash/plugin"
    @logger = Cabin::Channel.get(LogStash)

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
    if @config_string.nil? && @config_path.nil?
      fail(help + "\n" + I18n.t("logstash.agent.missing-configuration"))
    end

    @config_string = @config_string.to_s

    if @config_path
      # Append the config string.
      # This allows users to provide both -f and -e flags. The combination
      # is rare, but useful for debugging.
      @config_string = @config_string + load_config(@config_path)
    else
      # include a default stdin input if no inputs given
      if @config_string !~ /input *{/
        @config_string += DEFAULT_INPUT
      end
      # include a default stdout output if no outputs given
      if @config_string !~ /output *{/
        @config_string += DEFAULT_OUTPUT
      end
    end


    begin
      pipeline = LogStash::Pipeline.new(@config_string, @pipeline_settings)
    rescue LoadError => e
      fail("Configuration problem.")
    end

    # Make SIGINT shutdown the pipeline.
    sigint_id = Stud::trap("INT") do

      if @interrupted_once
        @logger.fatal(I18n.t("logstash.agent.forced_sigint"))
        exit
      else
        @logger.warn(I18n.t("logstash.agent.sigint"))
        Thread.new(@logger) {|logger| sleep 5; logger.warn(I18n.t("logstash.agent.slow_shutdown")) }
        @interrupted_once = true
        shutdown(pipeline)
      end
    end

    # Make SIGTERM shutdown the pipeline.
    sigterm_id = Stud::trap("TERM") do
      @logger.warn(I18n.t("logstash.agent.sigterm"))
      shutdown(pipeline)
    end

    Stud::trap("HUP") do
      @logger.info(I18n.t("logstash.agent.sighup"))
      configure_logging(log_file)
    end

    # Stop now if we are only asking for a config test.
    if config_test?
      report "Configuration OK"
      return
    end

    @logger.unsubscribe(stdout_logs) if show_startup_errors

    # TODO(sissel): Get pipeline completion status.
    pipeline.run
    return 0
  rescue LogStash::ConfigurationError => e
    @logger.unsubscribe(stdout_logs) if show_startup_errors
    report I18n.t("logstash.agent.error", :error => e)
    if !config_test?
      report I18n.t("logstash.agent.configtest-flag-information")
    end
    return 1
  rescue => e
    @logger.unsubscribe(stdout_logs) if show_startup_errors
    report I18n.t("oops", :error => e)
    report e.backtrace if @logger.debug? || $DEBUGLIST.include?("stacktrace")
    return 1
  ensure
    @log_fd.close if @log_fd
    Stud::untrap("INT", sigint_id) unless sigint_id.nil?
    Stud::untrap("TERM", sigterm_id) unless sigterm_id.nil?
  end # def execute

  def shutdown(pipeline)
    pipeline.shutdown do
      ::LogStash::ShutdownWatcher.start(pipeline)
    end
  end

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

  def load_config(path)
    begin
      uri = URI.parse(path)

      case uri.scheme
      when nil then
        local_config(path)
      when /http/ then
        fetch_config(uri)
      when "file" then
        local_config(uri.path)
      else
        fail(I18n.t("logstash.agent.configuration.scheme-not-supported", :path => path))
      end
    rescue URI::InvalidURIError
      # fallback for windows.
      # if the parsing of the file failed we assume we can reach it locally.
      # some relative path on windows arent parsed correctly (.\logstash.conf)
      local_config(path)
    end
  end

  def local_config(path)
    path = File.expand_path(path)
    path = File.join(path, "*") if File.directory?(path)

    if Dir.glob(path).length == 0
      fail(I18n.t("logstash.agent.configuration.file-not-found", :path => path))
    end

    config = ""
    encoding_issue_files = []
    Dir.glob(path).sort.each do |file|
      next unless File.file?(file)
      if file.match(/~$/)
        @logger.debug("NOT reading config file because it is a temp file", :file => file)
        next
      end
      @logger.debug("Reading config file", :file => file)
      cfg = File.read(file)
      if !cfg.ascii_only? && !cfg.valid_encoding?
        encoding_issue_files << file
      end
      config << cfg + "\n"
    end
    if (encoding_issue_files.any?)
      fail("The following config files contains non-ascii characters but are not UTF-8 encoded #{encoding_issue_files}")
    end
    return config
  end # def load_config

  def fetch_config(uri)
    begin
      Net::HTTP.get(uri) + "\n"
    rescue Exception => e
      fail(I18n.t("logstash.agent.configuration.fetch-failed", :path => uri.to_s, :message => e.message))
    end
  end

end # class LogStash::Agent
