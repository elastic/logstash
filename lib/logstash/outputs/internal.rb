require "logstash/namespace"
require "logstash/outputs/base"

class LogStash::Outputs::Internal < LogStash::Outputs::Base
  config_name "internal"

  attr_accessor :callback

  public
  def register
    @logger.info("Registering internal output (for testing!)")
    @callbacks ||= []
  end # def register

  public
  def receive(event)
    if @callbacks.empty?
      @logger.error("No callback for output #{@url}, cannot receive")
      return
    end

    @callbacks.each do |callback|
      callback.call(event)
    end
  end # def event

  public
  def subscribe(&block)
    @callbacks ||= []
    @callbacks << block
  end
end # class LogStash::Outputs::Internal
