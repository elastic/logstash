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

    @jsrule_source = <<EOS
function CloneObject(obj)
{
	var target = {}
	for (var i in obj) {
		if (obj.hasOwnProperty(i)) {
			target[i] = obj[i]
		}
	}
	return target
}

function jsrule()
{
        _events = []
	// If there is Function in apply, execute it over the event, otherwise, push in array
        if (rule.apply != "undefined" && rule.apply instanceof Function) {
        	tmp = rule.apply(event)
		// If result is an array, assign it to events, otherwise push in array
		if (tmp != "undefined" && tmp instanceof Array)
			_events = tmp
		else 
			_events.push(tmp)
        } else { 
        	_events.push(event)
	}

        _result = []
	// For each event, apply condition(s), cloning the object
        for(ev in _events)
          for(cd in rule.conditions) {
	    _result.push(rule.conditions[cd](CloneObject(_events[ev])))
	  }
	
        return _result
}
EOS

  end # def register

  public
  def filter(event)
    return unless filter?(event)

    Rhino::Context.open do |context|
      context['event'] = event.to_hash
      context.eval(@jsrule_source)
      context.eval(@rule)
      context.eval("jsrule()").each do |emitted_event_data|
        #@logger.debug(emitted_event_data)
        emitted_event = LogStash::Event.new(emitted_event_data)
        filter_matched(emitted_event)
        yield emitted_event
      end
    end

  end # def filter
end # class LogStash::Filters::Ruby
