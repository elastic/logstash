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

class LogStash::Runner < Clamp::Command

  DEFAULT_INPUT = "input { stdin { type => stdin } }"
  DEFAULT_OUTPUT = "output { stdout { codec => rubydebug } }"

  option ["-f", "--config"], "CONFIG_PATH",
    I18n.t("logstash.runner.flag.config"),
    :attribute_name => :config_path

  option "-e", "CONFIG_STRING",
    I18n.t("logstash.runner.flag.config-string",
           :default_input => DEFAULT_INPUT, :default_output => DEFAULT_OUTPUT),
    :default => "", :attribute_name => :config_string

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

  def initialize(*args)
    super(*args)
    @pipeline_settings ||= { :pipeline_id => "main" }
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

  attr_reader :agent

  def execute
    require "logstash/util"
    require "logstash/util/java_version"
    require "stud/task"
    require "cabin" # gem 'cabin'

    # Configure Logstash logging facility, this need to be done before everything else to
    # make sure the logger has the correct settings and the log level is correctly defined.
    configure_logging(log_file)

    @agent = LogStash::Agent.new({ :collect_metric => true,
                                   :logger => @logger, :debug => debug?, :node_name => node_name })

    LogStash::Util::set_thread_name(self.class.name)

    if RUBY_VERSION < "1.9.2"
      $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
      return 1
    end

    # Print a warning to STDERR for bad java versions
    LogStash::Util::JavaVersion.warn_on_bad_java_version

    LogStash::ShutdownWatcher.unsafe_shutdown = unsafe_shutdown?
    LogStash::ShutdownWatcher.logger = @logger

    configure

    if version?
      show_version
      return 0
    end

    return start_shell(@ruby_shell, binding) if @ruby_shell

    if @config_string.nil? && @config_path.nil?
      fail(I18n.t("logstash.runner.missing-configuration"))
    end

    config_string = format_config(@config_path, @config_string)

    @agent.add_pipeline("base", config_string, @pipeline_settings)

    if config_test?
      puts "Configuration OK"
    else
      task = Stud::Task.new { @agent.execute }
      return task.wait
    end

  rescue LoadError => e
    fail("Configuration problem.")
  rescue LogStash::ConfigurationError => e
    @logger.fatal I18n.t("logstash.error", :error => e)
    if !config_test?
      @logger.warn I18n.t("logstash.runner.configtest-flag-information")
    end
    show_short_help
    return 1
  rescue => e
    @logger.fatal I18n.t("oops", :error => e)
    @logger.debug e.backtrace if $DEBUGLIST.include?("stacktrace")
  ensure
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

      @logger.subscribe(STDOUT, :level => :fatal)
      @logger.subscribe(@log_fd)
      @logger.terminal "Sending logstash logs to #{path}."
    else
      @logger.subscribe(STDOUT)
    end

    # TODO(sissel): redirect stdout/stderr to the log as well
    # http://jira.codehaus.org/browse/JRUBY-7003
  end # def configure_logging

  def format_config(config_path, config_string)
    config_string = config_string.to_s
    if config_path
      # Append the config string.
      # This allows users to provide both -f and -e flags. The combination
      # is rare, but useful for debugging.
      config_string = config_string + load_config(config_path)
    else
      # include a default stdin input if no inputs given
      if config_string !~ /input *{/
        config_string += DEFAULT_INPUT
      end
      # include a default stdout output if no outputs given
      if config_string !~ /output *{/
        config_string += DEFAULT_OUTPUT
      end
    end
    config_string
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
        fail(I18n.t("logstash.runner.configuration.scheme-not-supported", :path => path))
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
      fail(I18n.t("logstash.runner.configuration.file-not-found", :path => path))
    end

    config = ""
    encoding_issue_files = []
    Dir.glob(path).sort.each do |file|
      next unless File.file?(file)
      if file.match(/~$/)
        @logger.debug("NOT reading config file because it is a temp file", :config_file => file)
        next
      end
      @logger.debug("Reading config file", :config_file => file)
      cfg = File.read(file)
      if !cfg.ascii_only? && !cfg.valid_encoding?
        encoding_issue_files << file
      end
      config << cfg + "\n"
      if config_test?
        @logger.debug? && @logger.debug("\nThe following is the content of a file", :config_file => file.to_s)
        @logger.debug? && @logger.debug("\n" + cfg + "\n\n")
      end
    end
    if (encoding_issue_files.any?)
      fail("The following config files contains non-ascii characters but are not UTF-8 encoded #{encoding_issue_files}")
    end
    if config_test?
      @logger.debug? && @logger.debug("\nThe following is the merged configuration")
      @logger.debug? && @logger.debug("\n" + config + "\n\n")
    end
    return config
  end # def load_config

  def fetch_config(uri)
    begin
      Net::HTTP.get(uri) + "\n"
    rescue Exception => e
      fail(I18n.t("logstash.runner.configuration.fetch-failed", :path => uri.to_s, :message => e.message))
    end
  end

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
end # class LogStash::Runner
