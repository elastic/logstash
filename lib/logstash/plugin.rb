require "logstash/namespace"
require "logstash/logging"
require "logstash/config/mixin"

class LogStash::Plugin
  attr_accessor :params
  attr_accessor :logger

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
    @logger = LogStash::Logger.new(STDOUT)
    @logger.level = $DEBUG ? :debug : :warn
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
    description = @config \
      .select { |k,v| !v.nil? && (v.respond_to?(:empty?) && !v.empty?) } \
      .collect { |k,v| "#{k}=>#{v.inspect}" }
    return "<#{self.class.name} #{description.join(", ")}>"
  end
end # class LogStash::Plugin
