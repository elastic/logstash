require "logstash/namespace"
require "logstash/logging"
require "logstash/config/mixin"

class LogStash::Plugin

  # This method is called when someone or something wants this plugin to shut
  # down. When you successfully shutdown, you must call 'finished'
  # You must also call 'super' in any subclasses.
  public
  def shutdown(queue)
    # By default, shutdown is assumed a no-op for all plugins.
    # If you need to take special efforts to shutdown (like waiting for
    # an operation to complete, etc)
    teardown
    @logger.info("Got shutdown signal for #{self}")

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
      @logger.info("Sending shutdown event to agent queue. (plugin #{to_s})")
      @shutdown_queue << self
    end

    if @plugin_state != :finished
      @logger.info("Plugin #{to_s} is finished")
      @plugin_state = :finished
    end
  end # def finished

  # Subclasses should implement this teardown method if you need to perform any
  # special tasks during shutdown (like flushing, etc.)
  public
  def teardown
    # nothing by default
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

end # class LogStash::Plugin
