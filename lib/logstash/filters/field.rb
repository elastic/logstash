require "logstash/filters/base"
require "ostruct"

class LogStash::Filters::Field < LogStash::Filters::Base
  class EvalSpace < OpenStruct
    def get_binding
      return binding
    end
  end

  def initialize(config = {})
    super
  end # def initialize

  def register
    # nothing to do
  end # def register

  def filter(event)
    data = EvalSpace.new(event.to_hash)

    @config.each do |condition|
      if data.instance_eval(condition)
        return # This event is OK, matches the condition.
      end
    end
    event.cancel
  end
end # class LogStash::Filters::Field
