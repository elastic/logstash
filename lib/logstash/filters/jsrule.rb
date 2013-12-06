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
function CloneObject(obj) {
    var target = {}, i;
    for (i in obj) {
        if (obj.hasOwnProperty(i)) {
            target[i] = obj[i];
        }
    }
    return target;
}

function JsRule(iRule) {
	this.rule = iRule;
}

JsRule.prototype.process = function(iEvent) {
    var _events = [],
        tmp_events, result, ev, cd;
    
    // If there is Function in apply, execute it over the event, otherwise, push in array
    if (this.rule.apply !== "undefined" && this.rule.apply instanceof Function) {
        tmp_events = this.rule.apply(iEvent);
        // If result is an array, assign it to events, otherwise push in array
        if (tmp_events !== "undefined" && tmp_events instanceof Array) {
            _events = tmp_events;
        } else {
            _events.push(tmp_events);
        }
    } else {
        _events.push(iEvent);
    }

    _result = [];
    // For each event, apply condition(s), cloning the object
    for (ev = 0; ev < _events.length; ev++) {
        for (cd = 0; cd < this.rule.conditions.length; cd++) {
            _result.push(this.rule.conditions[cd](CloneObject(_events[ev])));
        }
    }
    return _result;
}

jsrule = new JsRule(rule);
EOS
  
  @jscontext = Rhino::Context.new
  # TODO move optimization_level in settings?
  @jscontext.optimization_level = 6
  @jscontext.eval @rule + @jsrule_source
  @jsrule = @jscontext['jsrule']

  end # def register

  public
  def filter(event)
    return unless filter?(event)
    event.cancel
    begin
      @jsrule.process(event.to_hash).each do |emitted_event_data_js|
        # TODO The following 2 lines shouldn't be necessary! See https://github.com/cowboyd/therubyrhino/issues/27
        emitted_event_data = emitted_event_data_js.to_hash
        emitted_event_data['@timestamp'] = Rhino.to_ruby(emitted_event_data_js['@timestamp'])
        emitted_event = LogStash::Event.new(emitted_event_data)
        filter_matched(emitted_event)
        yield emitted_event
      end
    rescue => exception
      # TODO event.tag("_jsrulefailure")
      @logger.warn("Dropped event due to " + exception.message, :event => event)
    end
  end # def filter
end # class LogStash::Filters::Ruby
