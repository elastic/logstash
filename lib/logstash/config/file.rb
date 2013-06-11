require "logstash/namespace"
require "logstash/config/grammar"
require "logstash/config/config_ast"
require "logstash/config/registry"
require "logstash/errors"
require "logger"

class LogStash::Config::File
  include Enumerable
  attr_accessor :logger

  public
  def initialize(text)
    @logger = Cabin::Channel.get(LogStash)
    @text = text
    @config = parse(text)
  end # def initialize

  def parse(text)
    grammar = LogStashConfigParser.new
    result = grammar.parse(text)
    if result.nil?
      raise LogStash::ConfigurationError, grammar.failure_reason
    end
    return result
  end # def parse

  def plugin(plugin_type, name, *args)
    klass = LogStash::Plugin.lookup(plugin_type, name)
    return klass.new(*args)
  end

  def each(type=nil, &block)
    plugins = @config.recursive_select { |e| e.is_a?(LogStash::Config::AST::Plugin) }
    plugins.each do |ast|
      next if !type.nil? && type != ast.plugin_type
      yield eval(ast.compile)
    end
  end # def each

end #  class LogStash::Config::Parser

#agent.config(cfg)
