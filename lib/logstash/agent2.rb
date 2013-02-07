require "logstash/config/file"
require "logstash/pipeline"
require "clamp" # gem 'clamp'
require "cabin" # gem 'cabin'

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
  end

  option ["-V", "--version"], :flag,
    "Emit the version of logstash and its friends"

  plugin_paths = []
  option ["-p", "--pluginpath"] , "PATH",
    "A path of where to find plugins. This flag can be " \
    "given multiple times to include multiple paths. " \
    "Plugins are expected to be in a specific directory hierarchy: " \
    "'PATH/logstash/TYPE/NAME.rb' where TYPE is 'input' 'filter' or " \
    "'output' and NAME is the name of the plugin.",
    :attribute_name => :plugin_path  do |value|
    plugin_paths << value unless plugin_paths.include?(value)
    next plugin_paths
  end

  def warn(message)
    raise ConfigurationError, message
  end # def warn

  def fail(message)
    raise ConfigurationError, message
  end # def fail

  def execute
    if version?
      # TODO(sissel): This should emit the version of JRuby and ElasticSearch as
      # well. Perhaps also the versions of all gems?
      require "logstash/version"
      puts "logstash #{LOGSTASH_VERSION}"
      return 0
    end

    logger = Cabin::Channel.get
    #
    # Set with the -v (or -vv...) flag
    logger.level = verbosity?

    # The -l or --log flag was given
    if !log_file.nil?
      # TODO(sissel): Implement file output/rotation in Cabin.
      # TODO(sissel): Catch exceptions, report sane errors.
      file = File.new(log_file, "a")
      puts "Sending all output to #{log_file}."
      logger.subscribe(file)
    end

    # Append any plugin paths to the ruby search path
    plugin_path.each do |path|
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

    # @config_string, @config_path
    # @filter_workers
    # @watchdog_timeout
    # @plugin_path

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
end # class LogStash::Agent2
