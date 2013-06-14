require "clamp" # gem 'clamp'
require "logstash/errors"

class LogStash::Agent2 < Clamp::Command
  option ["-f", "--config"], "CONFIG_PATH",
    I18n.t("logstash.agent.flag.config"),
    :attribute_name => :config_path

  option "-e", "CONFIG_STRING",
    I18n.t("logstash.agent.flag.config-string"),
    :attribute_name => :config_string

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

  # Emit a warning message.
  def warn(message)
    # For now, all warnings are fatal.
    raise LogStash::ConfigurationError, message
  end # def warn

  # Emit a failure message and abort.
  def fail(message)
    raise LogStash::ConfigurationError, message
  end # def fail

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

    configure

    # You must specify a config_string or config_path
    if config_string.nil? && config_path.nil?
      puts help
      fail(I18n.t("logstash.agent.missing-configuration"))
    end

    if @config_path
      @config_string = load_config(@config_path)
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

    # TODO(sissel): Get pipeline completion status.
    pipeline.run
    return 0
  rescue LogStash::ConfigurationError => e
    puts I18n.t("logstash.agent.error", :error => e)
    return 1
  rescue => e
    puts I18n.t("oops", :error => e)
    puts e.backtrace if @logger.debug?
    return 1
  ensure
    Stud::untrap("INT", trap_id) unless trap_id.nil?
  end # def execute

  def show_version
    show_version_logstash

    if RUBY_PLATFORM == "java"
      show_version_java
      show_version_jruby
      show_version_elasticsearch
    end

    # Was the -v or --v flag given? Show all gems, too.
    show_gems if [:info, :debug].include?(verbosity?)
  end # def show_version

  def show_version_logstash
    require "logstash/version"
    puts "logstash #{LOGSTASH_VERSION}"
  end # def show_version_logstash

  def show_version_jruby
    puts "jruby #{JRUBY_VERSION} (ruby #{RUBY_VERSION})"
  end # def show_version_jruby

  def show_version_elasticsearch
    # Not running in the jar, assume elasticsearch jars are
    # in ../../vendor/jar/...
    if __FILE__ !~ /^(?:jar:)?file:/
      jarpath = File.join(File.dirname(__FILE__), "../../vendor/jar/elasticsearch*/lib/*.jar")
      Dir.glob(jarpath).each do |jar|
        require jar
      end
    end

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
    if verbosity? 
      # this is an array with length of how many times the flag is given
      if verbosity?.length == 1
        @logger.level = :info
      else
        @logger.level = :debug
      end
    end

    if quiet?
      @logger.level = :error
    elsif verbose?
      @logger.level = :info
    elsif debug?
      @logger.level = :debug
    else
      @logger.level = :warn
    end

    if !log_file.nil?
      # TODO(sissel): Implement file output/rotation in Cabin.
      # TODO(sissel): Catch exceptions, report sane errors.
      begin
        file = File.new(path, "a")
      rescue => e
        fail(I18n.t("logstash.agent.configuration.log_file_failed",
                    :path => path, :error => e))
      end

      puts "Sending all output to #{path}."
      @logger.subscribe(file)
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
      # aka, there must be file in path/logstash/{filters,inputs,outputs}/*.rb
      plugin_glob = File.join(path, "logstash", "{inputs,filters,outputs}", "*.rb")
      if Dir.glob(plugin_glob).empty?
        warn(I18n.t("logstash.agent.configuration.no_plugins_found",
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
      @logger.debug("Reading config file", :file => file)
      config << File.read(file) + "\n"
    end
    return config
  end # def load_config
end # class LogStash::Agent2
