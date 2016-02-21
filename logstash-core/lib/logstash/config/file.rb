# encoding: utf-8
require "logstash/namespace"
require "logstash/config/grammar"
require "logstash/config/config_ast"
require "logstash/config/registry"
require "logstash/errors"
require "logger"
java_import 'com.logstash.pipeline.graph.ConfigFile'

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
    com.logstash.pipeline.graph.ConfigFile.fromString(config_str, LogStash::Pipeline::PipelineComponentProcessor)
  end # def parse

  def plugin(plugin_type, name, *args)
    klass = LogStash::Plugin.lookup(plugin_type, name)
    return klass.new(*args)
  end

  def each
    @config.recursive_select(LogStash::Config::AST::Plugin)
  end
end #  class LogStash::Config::Parser

#agent.config(cfg)
