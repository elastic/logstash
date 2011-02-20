require "logstash/filters/base"
require "logstash/namespace"
require "ostruct"

class LogStash::Filters::Field < LogStash::Filters::Base

  # TODO(sissel): Finish this.
  config_name "field"

  class EvalSpace < OpenStruct
    def get_binding
      return binding
    end
  end

  public
  def register
    # nothing to do
  end # def register

  public
  def filter(event)
    data = EvalSpace.new(event.to_hash)

    @config.each do |condition|
      if data.instance_eval(condition)
        return # This event is OK, matches the condition.
      end
    end
    event.cancel
  end # def filter
end # class LogStash::Filters::Field
