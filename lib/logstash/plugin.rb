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
    # Try to load the plugin requested.
    # For example, load("filter", "grok") will try to require
    #   logstash/filters/grok
    #
    # And expects to find LogStash::Filters::Grok (or something similar based
    # on pattern matching

    path = "logstash/#{type}s/#{name}"
    require(path)

    base = LogStash.const_get("#{type.capitalize}s")
    klass = nil
    #klass_sym = base.constants.find { |c| c.to_s =~ /^#{Regexp.quote(name)}$/i }
    #if klass_sym.nil?

    # Look for a plugin by the config_name
    # the namespace can contain constants which are not for plugins classes (do not respond to :config_name)
    # for example, the ElasticSearch output adds the LogStash::Outputs::Elasticsearch::Protocols namespace
    klass_sym = base.constants.find { |c| o = base.const_get(c); o.respond_to?(:config_name) && o.config_name == name }
    klass = base.const_get(klass_sym)

    raise LoadError if klass.nil?

    return klass
  rescue LoadError => e
    raise LogStash::PluginLoadingError,
      I18n.t("logstash.pipeline.plugin-loading-error", :type => type, :name => name, :path => path, :error => e.to_s)
  end # def load
end # class LogStash::Plugin
