require "logstash/config/file"
require "clamp"

class LogStash::Agent2 < Clamp::Command
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
    "logstash will emit logs to standard output."

  verbosity = 0
  option "-v", :flag, "Increase verbosity of logstash internal logs. " \
    "Specifying once will show 'informational' logs. Specifying twice " \
    "will show 'debug' logs.", :attribute_name => :verbosity do
    verbosity += 1
  end

  option ["-V", "--version"], :flag,
    "Emit the version of logstash and its friends" do
    # TODO(sissel): This should emit the version of JRuby and ElasticSearch as
    # well. Perhaps also the versions of all gems?
    require "logstash/version"
    puts "logstash #{LOGSTASH_VERSION}"
    exit(0)
  end

  plugin_paths = []
  option ["-p", "--pluginpath"] , "PATH",
    "A colon-delimited path of where to find plugins. Plugins are expected " \
    "to be in a specific directory hierarchy: PATH/logstash/TYPE/NAME.rb - " \
    "where TYPE is 'input' 'filter' or 'output' and NAME is the name of the" \
    "plugin.", :attribute_name => :plugin_path  do |value|
    plugin_paths << value unless plugin_paths.include?(value)
  end

  def execute
  end # def execute
end # class LogStash::Agent2
