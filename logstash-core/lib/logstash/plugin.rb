# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "logstash/config/mixin"
require "logstash/instrument/null_metric"
require "concurrent"
require "securerandom"
require "logstash/plugins/registry"

class LogStash::Plugin
  include LogStash::Util::Loggable
  attr_accessor :params

  NL = "\n"

  include LogStash::Config::Mixin

  # Disable or enable metric logging for this specific plugin instance
  # by default we record all the metrics we can, but you can disable metrics collection
  # for a specific plugin.
  config :enable_metric, :validate => :boolean, :default => true

  # Add a unique `ID` to the plugin instance, this `ID` is used for tracking
  # information for a specific configuration of the plugin.
  #
  # ```
  # output {
  #  stdout {
  #    id => "ABC"
  #  }
  # }
  # ```
  #
  # If you don't explicitely set this variable Logstash will generate a unique name.
  config :id, :validate => :string

  def hash
    params.hash ^
    self.class.name.hash
  end


  def eql?(other)
    self.class.name == other.class.name && @params == other.params
  end

  def initialize(params=nil)
    @logger = self.logger
    @params = LogStash::Util.deep_clone(params)
    # The id should always be defined normally, but in tests that might not be the case
    # In the future we may make this more strict in the Plugin API
    @params["id"] ||= "#{self.class.config_name}_#{SecureRandom.uuid}"
  end

  # Return a uniq ID for this plugin configuration, by default
  # we will generate a UUID
  #
  # If the user defines a `id => 'ABC'` in the configuration we will return
  #
  # @return [String] A plugin ID
  def id
    @params["id"]
  end

  # close is called during shutdown, after the plugin worker
  # main task terminates
  def do_close
    @logger.debug("closing", :plugin => self.class.name)
    close
  end

  # Subclasses should implement this close method if you need to perform any
  # special tasks during shutdown (like flushing, etc.)
  def close
    # ..
  end

  def to_s
    return "#{self.class.name}: #{@params}"
  end

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

  def debug_info
    [self.class.to_s, original_params]
  end

  def metric=(new_metric)
    @metric = new_metric
  end

  def metric
    # We can disable metric per plugin if we want in the configuration
    # we will use the NullMetric in this case.
    @metric_plugin ||= if @enable_metric
                         # Fallback when testing plugin and no metric collector are correctly configured.
                         @metric.nil? ? LogStash::Instrument::NamespacedNullMetric.new : @metric
                       else
                         LogStash::Instrument::NamespacedNullMetric.new(@metric, :null)
                       end
  end
  # return the configured name of this plugin
  # @return [String] The name of the plugin defined by `config_name`
  def config_name
    self.class.config_name
  end


  # Look up a plugin by type and name.
  def self.lookup(type, name)
    path = "logstash/#{type}s/#{name}"
    LogStash::Registry.instance.lookup(type ,name) do |plugin_klass, plugin_name|
      is_a_plugin?(plugin_klass, plugin_name)
    end
    
  rescue LoadError, NameError => e
    logger.debug("Problems loading the plugin with", :type => type, :name => name, :path => path)
    raise(LogStash::PluginLoadingError, I18n.t("logstash.pipeline.plugin-loading-error", :type => type, :name => name, :path => path, :error => e.to_s))
  end

  public
  def self.declare_plugin(type, name)
    path = "logstash/#{type}s/#{name}"
    registry = LogStash::Registry.instance
    registry.register(path, self)
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
end # class LogStash::Plugin
