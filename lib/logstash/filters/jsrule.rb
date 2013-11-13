require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Ruby < LogStash::Filters::Base
  config_name "jsrule"
  milestone 1

  # The code to execute for every event.
  # You will have an 'event' variable available that is the event itself.
  config :rule, :validate => :string, :required => true

  public
  def register
    require 'rhino'

    @jsrule = JsRule.new
    # Load jsrule engine
    jsrule_source = <<EOS
function jsrule()
{
        _events = []
        if (rule.apply != "undefined" && rule.apply instanceof Function) {
                _events = rule.apply(event)
        } else {
                _events.push(event)
        }

        _result = []
        for(ev in _events)
          for(cd in rule.conditions)
                _result.push(cd(ev))
        
        return _result
}
EOS
    @jsrule.eval_js(jsrule_source)
    # Load specific rule
    @jsrule.eval_js(@rule)

  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @jsrule['event'] = event
    @jsrule.eval_js("result = jsrule()")

    @jsrule['result'].each do |emitted_event|
      filter_matched(emitted_event)
      yield emitted_event
    end
      
  end # def filter
end # class LogStash::Filters::Ruby
