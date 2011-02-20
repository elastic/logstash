require "logstash/namespace"
require "logstash/outputs/base"

class LogStash::Outputs::Internal < LogStash::Outputs::Base

  config_name "internal"

  public
  def initialize(url, config={}, &block)
    super
    @callback = block
  end # def initialize

  public
  def register
    @logger.info("Registering output #{@url}")
  end # def register

  public
  def receive(event)
    if !@callback
      @logger.error("No callback for output #{@url}, cannot receive")
      return
    end
    @callback.call(event)
  end # def event

  # Set the callback by passing a block of code
  public
  def callback(&block)
    @callback = block
  end

  # Set the callback by passing a proc object
  public
  def callback=(proc_block)
    @callback = proc_block
  end
end # class LogStash::Outputs::Internal
