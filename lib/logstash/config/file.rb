require "logstash/namespace"
require "logstash/config/grammar"
require "logstash/config/registry"
require "logger"

class LogStash::Config::File
  attr_accessor :logger

  public
  def initialize(path=nil, string=nil)
    @path = path
    @string = string
    @logger = Cabin::Channel.get(LogStash)

    if (path.nil? and string.nil?) or (!path.nil? and !string.nil?)
       raise "Must give path or string, not both or neither"
    end
  end # def initialize

  def _get_config_data
    if @string.nil?
      File.new(@path).read
    else
      @string
    end
  end

  def _get_config(data)
    grammar = LogStash::Config::Grammar.new
    grammar.parse(data)
    grammar.config
  end

  public
  def parse
    @config = _get_config(_get_config_data);

    registry = LogStash::Config::Registry::registry
    each do |o|
      # Load the base class for the type given (like inputs/base, or filters/base)
      # TODO(sissel): Error handling
      tryload o[:type], :base
      type = registry[o[:type]]

      # Load the plugin itself (inputs/file, outputs/rabbitmq, etc)
      # TODO(sissel): Error handling
      tryload o[:type], o[:plugin]
      plugin = registry[o[:plugin]]

      if type.nil?
        @logger.info("Unknown plugin", :type => o[:type], :plugin => o[:plugin])
      end
      yield :type => type, :plugin => plugin, :parameters => o[:parameters]

    end
  end # def parse

  public
  def tryload(parent, child)
    child = child.downcase if child.is_a? String
    begin
      loaded = require("logstash/#{parent}s/#{child}")
    rescue LoadError => e
      if child == :base
        @logger.fatal("Failure loading plugin type '#{parent}' - is that " \
                      "really a valid plugin type? (check for typos!)")
      else
        @logger.fatal("Failure loading plugin from config: " \
                      "'#{parent} { #{child} { ... } }' - is that " \
                      "really a valid #{parent} plugin? (check for typos!)")
      end
      raise e
    end
  end # def tryload

  public
  def each(&block)
    # First level is the components
    # Like:
    #   input {
    #     ...
    #   }
    @config.each do |type, plugin_config_array|
      # plugin_config_array has arrays of each component config:
      # input {
      #   rabbitmq { ... }
      #   file { ... }
      #   file { ... }
      # }
      plugin_config_array.each do |plugin_config|
        yield({
          :type => type,
          :plugin => plugin_config.keys.first,
          :parameters => plugin_config.values.first
        })
      end
    end # @config.each
  end # def each

end #  class LogStash::Config::Parser

#agent.config(cfg)
