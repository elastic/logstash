require "logstash/config/file"
require "logstash/pipeline"
require "clamp" # gem 'clamp'
require "cabin" # gem 'cabin'
require "sys/uname" # gem 'sys-uname'

class LogStash::Agent2 < Clamp::Command
  class ConfigurationError < StandardError; end

  option ["-f", "--config"], "CONFIG_PATH",
    "Load the logstash config from a specific file or directory. " \
    "If a direcory is given, all files in that directory will " \
    "be concatonated in lexicographical order and then parsed as " \
    "a single config file. You can also specify wildcards (globs)" \
    "and any matched files will be loaded in the order described above",
    :attribute_name => :config_path

  option "-e", "CONFIG_STRING",
    "Use the given string as the configuration data. Same syntax as " \
    "the config file. If not input is specified, then " \
    "'stdin { type => stdin }' is the default input. If no output is " \
    "specified, then 'stdout { debug => true }}' is default output.",
    :attribute_name => :config_string

  option ["-w", "--filterworkers"], "COUNT",
    "Sets the number of filter workers to run.",
    :attribute_name => :filter_workers, :default => 1, &:to_i

  option "--watchdog-timeout", "SECONDS", 
    "Set the filter watchdog timeout (in seconds). This timeout is used" \
    " to detect stuck filters; stuck filters usually symptoms of bugs. " \
    "When a filter takes longer than TIMEOUT seconds, it will cause " \
    "logstash to abort.", :default => 10, &:to_f

  option ["-l", "--log"], "FILE",
    "Write logstash internal logs to the given file. Without this flag, " \
    "logstash will emit logs to standard output.",
    :attribute_name => :log_file

  verbosity = 0
  option "-v", :flag, "Increase verbosity of logstash internal logs. " \
    "Specifying once will show 'informational' logs. Specifying twice " \
    "will show 'debug' logs.", :default => :warn, 
    :attribute_name => :verbosity do
    verbosity += 1

    if verbosity == 1
      next :info
    else
      next :debug
    end
  end # -v

  option ["-V", "--version"], :flag,
    "Emit the version of logstash and its friends"

  plugin_paths = []
  option ["-p", "--pluginpath"] , "PATH",
    "A path of where to find plugins. This flag can be " \
    "given multiple times to include multiple paths. " \
    "Plugins are expected to be in a specific directory hierarchy: " \
    "'PATH/logstash/TYPE/NAME.rb' where TYPE is 'input' 'filter' or " \
    "'output' and NAME is the name of the plugin.",
    :attribute_name => :plugin_paths  do |value|
    plugin_paths << value unless plugin_paths.include?(value)
    next plugin_paths
  end # -p / --pluginpath

  # Emit a warning message.
  def warn(message)
    # For now, all warnings are fatal.
    raise ConfigurationError, message
  end # def warn

  # Emit a failure message and abort.
  def fail(message)
    raise ConfigurationError, message
  end # def fail

  # Run the agent. This method is invoked after clamp parses the
  # flags given to this program.
  def execute
    if version?
      show_version
      return 0
    end

    logger = Cabin::Channel.get
    # Set with the -v (or -vv...) flag
    logger.level = verbosity?

    configure

    # @config_string, @config_path
    # @filter_workers
    # @watchdog_timeout

    puts "GO"
    sleep 5
    pipeline = LogStash::Pipeline.new(@config_string)
    trap_id = Stud::trap("INT") { pipeline.shutdown }
    pipeline.run
    return 0
  rescue ConfigurationError => e
    puts "Error: #{e}"
    return 1

  rescue => e
    puts e
    puts e.backtrace
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
    configure_logging(log_file) if !log_file.nil?
    configure_plugin_path(plugin_paths) if !plugin_paths.nil??
  end # def configure

  # Point logging at a specific path.
  def configure_logging(path)
    logger = Cabin::Channel.get
    # TODO(sissel): Implement file output/rotation in Cabin.
    # TODO(sissel): Catch exceptions, report sane errors.
    begin
      file = File.new(path, "a")
    rescue => e
      fail("Failed to open #{path} for writing: #{e}")
    end
    puts "Sending all output to #{path}."
    logger.subscribe(file)
  end # def configure_logging

  # Validate and add any paths to the list of locations
  # logstash will look to find plugins.
  def configure_plugin_path(paths)
    # Append any plugin paths to the ruby search path
    paths.each do |path|
      # Verify the path exists
      if !Dir.exists?(path)
        warn("This plugin path does not exist: '#{path}'")
      end

      # TODO(sissel): Verify the path looks like the correct form.
      # aka, there must be file in path/logstash/{filters,inputs,outputs}/*.rb
      plugin_glob = File.join(path, "logstash", "{inputs,filters,outputs}", "*.rb")
      if Dir.glob(plugin_glob).empty?
        warn("No plugins were found at #{plugin_glob}")
      end

      # We push plugin paths to the front of the LOAD_PATH so that folks
      # can override any core logstash plugins if they need to.
      logger.debug("Adding plugin path", :path => path)
      $LOAD_PATH.unshift(path)
    end
  end # def configure_plugin_path
end # class LogStash::Agent2
