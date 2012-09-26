require "logstash/namespace"
require "logstash/outputs/base"

# This output is only used for internal logstash testing and
# is not useful for general deployment.
class LogStash::Outputs::Internal < LogStash::Outputs::Base
  config_name "internal"
  plugin_status "stable"

  attr_accessor :callbacks

  public 
  def initialize(*args)
    super(*args)
    @callbacks ||= []
  end # def initialize

  public
  def register
    @logger.info("Registering internal output (for testing!)")
  end # def register

  public
  def receive(event)
    return unless output?(event)

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
