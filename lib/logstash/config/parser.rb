require "logstash/namespace"
require "logstash/config/grammar"
require "logstash/config/registry"
require "logstash/agent"

class LogStash::Config::File
  def initialize(file)
    @file = file
  end

  def parse
    grammar = LogStash::Config::Grammar.new
    grammar.parse(File.new(@file).read)
    @config = grammar.config
  end

  def each(&block)
    #ap @config

    # First level is the components
    # Like:
    #   inputs {
    #     ...
    #   }
    @config.each do |type, plugin_config_array|
      # plugin_config_array has arrays of each component config:
      # inputs {
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

#agent = LogStash::Agent.new({})
#require "logstash/inputs/base"
#require "logstash/inputs/amqp"
cfg = LogStash::Config::File.new(ARGV[0])
cfg.parse
registry = LogStash::Config::Registry::registry
cfg.each do |o|
  ap ["Config", o]

  # Load the base class for the type given (like inputs/base, or filters/base)
  # TODO(sissel): Error handling
  require "logstash/#{o[:type]}s/base"
  type = registry[o[:type]]

  # Load the plugin itself (inputs/file, outputs/amqp, etc)
  # TODO(sissel): Error handling
  require "logstash/#{o[:type]}s/#{o[:plugin].downcase}"
  config_class = registry[o[:plugin]]
  if type
    ap :got => [type, config_class]
  else
    puts "Unknown config #{o.awesome_inspect}"
  end
end
#agent.config(cfg)
