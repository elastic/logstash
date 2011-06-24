require "logstash/namespace"
require "logstash/config/grammar"
require "logstash/config/registry"
require "logstash/agent"

class LogStash::Config::File
  public
  def initialize(path=nil, string=nil)
    @path = path
    @string = string

    if (path.nil? and string.nil?) or (!path.nil? and !string.nil?)
       raise "Must give path or string, not both or neither"
    end
  end # def initialize

  public
  def parse
    grammar = LogStash::Config::Grammar.new

    if @string.nil?
      grammar.parse(File.new(@path).read)
    else
      grammar.parse(@string)
    end

    @config = grammar.config
    
    registry = LogStash::Config::Registry::registry
    each do |o|
      # Load the base class for the type given (like inputs/base, or filters/base)
      # TODO(sissel): Error handling
      tryload o[:type], :base
      type = registry[o[:type]]

      # Load the plugin itself (inputs/file, outputs/amqp, etc)
      # TODO(sissel): Error handling
      tryload o[:type], o[:plugin]
      plugin = registry[o[:plugin]]

      if type.nil?
        puts "Unknown config #{o[:type]}/#{o[:plugin]}"
      end

      yield :type => type, :plugin => plugin, :parameters => o[:parameters]
    end
  end # def parse

  public
  def tryload(parent, child)
    child = child.downcase if child.is_a? String
    begin
      loaded = (require "logstash/#{parent}s/#{child}")
      #if loaded
        #puts "Loading logstash/#{parent}s/#{child}"
      #end
    rescue => e
      if child == :base
        $stderr.puts "Failure loading base class '#{parent}': #{e.inspect}"
      else
        $stderr.puts "Failure loading plugin #{parent}s/#{child}: #{e.inspect}"
      end
      raise e
    end
  end # def tryload

  public
  def each(&block)
    #ap @config

    # First level is the components
    # Like:
    #   input {
    #     ...
    #   }
    @config.each do |type, plugin_config_array|
      # plugin_config_array has arrays of each component config:
      # input {
      #   amqp { ... }
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
