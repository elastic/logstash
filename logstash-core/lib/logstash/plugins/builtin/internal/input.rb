module ::LogStash; module Plugins; module Builtin; module Internal; class Input < ::LogStash::Inputs::Base
  include org.logstash.plugins.internal.InternalInput

  config_name "internal"

  config :address, :validate => :string, :required => true

  def register
    # May as well set this up here, writers won't do anything until
    # @running is set to false
    @running = java.util.concurrent.atomic.AtomicBoolean.new(false)
    listen_successful = org.logstash.plugins.internal.Common.listen(address, self)
    if !listen_successful
      raise ::LogStash::ConfigurationError, "Internal input at '#{@address}' already bound! Addresses must be globally unique across pipelines."
    end
  end

  def run(queue)
    @queue = queue
    @running.set(true)

    while @running.get()
      sleep 0.5
    end
  end

  def running?
    @running && @running.get()
  end

  # Returns false if the receive failed due to a stopping input
  # To understand why this value is useful see Internal.send_to
  def internalReceive(event)
    return false if !@running.get()

    decorate(event)
    @queue << event

    return true
  end

  def stop
    # We stop receiving events before we unlisten to prevent races
    @running.set(false) if @running # If register wasn't yet called, no @running!
    org.logstash.plugins.internal.Common.unlisten(address, self)
  end

  def isRunning
    @running.get
  end

end; end; end; end; end