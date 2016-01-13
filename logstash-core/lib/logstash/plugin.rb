# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "logstash/config/mixin"
require "cabin"
require "concurrent"

class LogStash::Plugin
  attr_accessor :params
  attr_accessor :logger

  NL = "\n"

  public
  def hash
    params.hash ^
    self.class.name.hash
  end

  public
  def eql?(other)
    self.class.name == other.class.name && @params == other.params
  end

  public
  def initialize(params=nil)
    @params = LogStash::Util.deep_clone(params)
    @logger = Cabin::Channel.get(LogStash)
  end

  # close is called during shutdown, after the plugin worker
  # main task terminates
  public
  def do_close
    @logger.debug("closing", :plugin => self)
    close
  end

  # Subclasses should implement this close method if you need to perform any
  # special tasks during shutdown (like flushing, etc.)
  public
  def close
    # ..
  end

  def to_s
    return "#{self.class.name}: #{@params}"
  end

  public
  def inspect
    if !@params.nil?
      description = @params
        .reject { |k, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }
        .collect { |k, v| "#{k}=>#{v.inspect}" }
      return "<#{self.class.name} #{description.join(", ")}>"
    else
      return "<#{self.class.name} --->"
    end
  end

  public
  def debug_info
    [self.class.to_s, original_params]
  end

  # Look up a plugin by type and name.
  public
  def self.lookup(type, name)
    path = "logstash/#{type}s/#{name}"

    # first check if plugin already exists in namespace and continue to next step if not
    begin
      return namespace_lookup(type, name)
    rescue NameError
      logger.debug("Plugin not defined in namespace, checking for plugin file", :type => type, :name => name, :path => path)
    end

    # try to load the plugin file. ex.: lookup("filter", "grok") will require logstash/filters/grok
    require(path)

    # check again if plugin is now defined in namespace after the require
    namespace_lookup(type, name)
  rescue LoadError, NameError => e
    raise(LogStash::PluginLoadingError, I18n.t("logstash.pipeline.plugin-loading-error", :type => type, :name => name, :path => path, :error => e.to_s))
  end

  private

  # lookup a plugin by type and name in the existing LogStash module namespace
  # ex.: namespace_lookup("filter", "grok") looks for LogStash::Filters::Grok
  # @param type [String] plugin type, "input", "ouput", "filter"
  # @param name [String] plugin name, ex.: "grok"
  # @return [Class] the plugin class or raises NameError
  # @raise NameError if plugin class does not exist or is invalid
  def self.namespace_lookup(type, name)
    type_const = "#{type.capitalize}s"
    namespace = LogStash.const_get(type_const)
    # the namespace can contain constants which are not for plugins classes (do not respond to :config_name)
    # namespace.constants is the shallow collection of all constants symbols in namespace
    # note that below namespace.const_get(c) should never result in a NameError since c is from the constants collection
    klass_sym = namespace.constants.find { |c| is_a_plugin?(namespace.const_get(c), name) }
    klass = klass_sym && namespace.const_get(klass_sym)
    raise(NameError) unless klass
    klass
  end

  # check if klass is a valid plugin for name
  # @param klass [Class] plugin class
  # @param name [String] plugin name
  # @return [Boolean] true if klass is a valid plugin for name
  def self.is_a_plugin?(klass, name)
    klass.ancestors.include?(LogStash::Plugin) && klass.respond_to?(:config_name) && klass.config_name == name
  end

  # @return [Cabin::Channel] logger channel for class methods
  def self.logger
    @logger ||= Cabin::Channel.get(LogStash)
  end
end # class LogStash::Plugin
