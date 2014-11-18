# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "logstash/config/mixin"
require "cabin"

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
    @params = params
    @logger = Cabin::Channel.get(LogStash)
  end

  # This method is called when someone or something wants this plugin to shut
  # down. When you successfully shutdown, you must call 'finished'
  # You must also call 'super' in any subclasses.
  public
  def shutdown(queue)
    # By default, shutdown is assumed a no-op for all plugins.
    # If you need to take special efforts to shutdown (like waiting for
    # an operation to complete, etc)
    teardown
    @logger.info("Received shutdown signal", :plugin => self)

    @shutdown_queue = queue
    if @plugin_state == :finished
      finished
    else
      @plugin_state = :terminating
    end
  end # def shutdown

  # You should call this method when you (the plugin) are done with work
  # forever.
  public
  def finished
    # TODO(sissel): I'm not sure what I had planned for this shutdown_queue
    # thing
    if @shutdown_queue
      @logger.info("Sending shutdown event to agent queue", :plugin => self)
      @shutdown_queue << self
    end

    if @plugin_state != :finished
      @logger.info("Plugin is finished", :plugin => self)
      @plugin_state = :finished
    end
  end # def finished

  # Subclasses should implement this teardown method if you need to perform any
  # special tasks during shutdown (like flushing, etc.)
  public
  def teardown
    # nothing by default
    finished
  end

  # This method is called when a SIGHUP triggers a reload operation
  public
  def reload
    # Do nothing by default
  end

  public
  def finished?
    return @plugin_state == :finished
  end # def finished?

  public
  def running?
    return @plugin_state != :finished
  end # def finished?

  public
  def terminating?
    return @plugin_state == :terminating
  end # def terminating?

  public
  def to_s
    return "#{self.class.name}: #{@params}"
  end

  protected
  def update_watchdog(state)
    Thread.current[:watchdog] = Time.now
    Thread.current[:watchdog_state] = state
  end

  protected
  def clear_watchdog
    Thread.current[:watchdog] = nil
    Thread.current[:watchdog_state] = nil
  end

  public
  def inspect
    if !@config.nil?
      description = @config \
        .select { |k,v| !v.nil? && (v.respond_to?(:empty?) && !v.empty?) } \
        .collect { |k,v| "#{k}=>#{v.inspect}" }
      return "<#{self.class.name} #{description.join(", ")}>"
    else
      return "<#{self.class.name} --->"
    end
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
