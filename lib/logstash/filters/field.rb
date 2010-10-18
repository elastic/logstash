require "logstash/namespace"
require "ostruct"

class LogStash::Filters::Field
  class EvalSpace < OpenStruct
    def get_binding
      return binding
    end
  end

  def initialize(config = {})
    @config = config
  end # def initialize

  def register
    # nothing to do
  end # def register

  def filter(event)
    data = EvalSpace.new(event.to_hash)

    @config.each do |condition|
      if data.instance_eval(condition)
        return event
      end
    end
    event.cancel
    return event
  end
end # class LogStash::Filters::Grok
