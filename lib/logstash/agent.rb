# encoding: utf-8
require "clamp" # gem 'clamp'
require "logstash/environment"
require "logstash/errors"
require "i18n"

class LogStash::Agent < Clamp::Command
  option ["-f", "--config"], "CONFIG_PATH",
    I18n.t("logstash.agent.flag.config"),
    :attribute_name => :config_path

  option "-e", "CONFIG_STRING",
    I18n.t("logstash.agent.flag.config-string"),
    :default => "", :attribute_name => :config_string

  option ["-w", "--filterworkers"], "COUNT",
    I18n.t("logstash.agent.flag.filterworkers"),
    :attribute_name => :filter_workers, :default => 1, &:to_i

  option "--watchdog-timeout", "SECONDS",
    I18n.t("logstash.agent.flag.watchdog-timeout"),
    :default => 10, &:to_f

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
        @config_string += "input { stdin { type => stdin } }"
      end
      # include a default stdout output if no outputs given
      if @config_string !~ /output *{/
        @config_string += "output { stdout { codec => rubydebug } }"
      end
    end

    begin
      pipeline = LogStash::Pipeline.new(@config_string)
    rescue LoadError => e
      fail("Configuration problem.")
    end

    # Make SIGINT shutdown the pipeline.
    trap_id = Stud::trap("INT") do
      @logger.warn(I18n.t("logstash.agent.interrupted"))
      pipeline.shutdown
    end

    Stud::trap("HUP") do
      @logger.info(I18n.t("logstash.agent.sighup"))
      configure_logging(log_file)
    end

    pipeline.configure("filter-workers", filter_workers)

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
    Stud::untrap("INT", trap_id) unless trap_id.nil?
  end # def execute

  def show_version
    show_version_logstash

    if [:info, :debug].include?(verbosity?) || debug? || verbose?
      show_version_ruby

      if RUBY_PLATFORM == "java"
        show_version_java
        show_version_elasticsearch
      end

      if [:debug].include?(verbosity?) || debug?
        show_gems
      end
    end
  end # def show_version

  def show_version_logstash
    require "logstash/version"
    puts "logstash #{LOGSTASH_VERSION}"
  end # def show_version_logstash

  def show_version_ruby
    puts RUBY_DESCRIPTION
  end # def show_version_ruby

  def show_version_elasticsearch
    LogStash::Environment.load_elasticsearch_jars!

    $stdout.write("Elasticsearch: ");
    org.elasticsearch.Version::main([])
  end # def show_version_elasticsearch

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
    configure_plugin_path(plugin_paths) if !plugin_paths.nil?
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

  # Validate and add any paths to the list of locations
  # logstash will look to find plugins.
  def configure_plugin_path(paths)
    # Append any plugin paths to the ruby search path
    paths.each do |path|
      # Verify the path exists
      if !Dir.exists?(path)
        warn(I18n.t("logstash.agent.configuration.plugin_path_missing",
                    :path => path))

      end

      # TODO(sissel): Verify the path looks like the correct form.
      # aka, there must be file in path/logstash/{inputs,codecs,filters,outputs}/*.rb
      plugin_glob = File.join(path, "logstash", "{inputs,codecs,filters,outputs}", "*.rb")
      if Dir.glob(plugin_glob).empty?
        @logger.warn(I18n.t("logstash.agent.configuration.no_plugins_found",
                    :path => path, :plugin_glob => plugin_glob))
      end

      # We push plugin paths to the front of the LOAD_PATH so that folks
      # can override any core logstash plugins if they need to.
      @logger.debug("Adding plugin path", :path => path)
      $LOAD_PATH.unshift(path)
    end
  end # def configure_plugin_path

  def load_config(path)
    path = File.join(path, "*") if File.directory?(path)

    if Dir.glob(path).length == 0
      fail(I18n.t("logstash.agent.configuration.file-not-found", :path => path))
    end

    config = ""
    Dir.glob(path).sort.each do |file|
      next unless File.file?(file)
      if file.match(/~$/)
        @logger.debug("NOT reading config file because it is a temp file", :file => file)
        next
      end
      @logger.debug("Reading config file", :file => file)
      config << File.read(file) + "\n"
    end
    return config
  end # def load_config

end # class LogStash::Agent
