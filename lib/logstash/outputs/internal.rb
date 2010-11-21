require "logstash/outputs/base"

class LogStash::Outputs::Internal < LogStash::Outputs::Base
  def initialize(url, config={}, &block)
    super
    @callback = block
  end

  def register
    # nothing to do
  end # def register

  def receive(event)
    if !@callback
      @logger.error("No callback for output #{@url}, cannot receive")
      return
    end
    @callback.call(event)
  end # def event

  # Set the callback by passing a block of code
  def callback(&block)
    @callback = block
  end

  # Set the callback by passing a proc object
  def callback=(proc_block)
    @callback = proc_block
  end
end # class LogStash::Outputs::Internal
