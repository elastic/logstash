# encoding: utf-8

require "logstash/namespace"
require "logstash/json"
require "jruby_event_ext"
require "jruby_timestamp_ext"
require "logstash/timestamp"
require "logstash/string_interpolation"

# transient pipeline events for normal in-flow signaling as opposed to
# flow altering exceptions. for now having base classes is adequate and
# in the future it might be necessary to refactor using like a BaseEvent
# class to have a common interface for all pipeline events to support
# eventual queueing persistence for example, TBD.
module LogStash
  class SignalEvent
    def flush?; raise "abstract method"; end;
    def shutdown?; raise "abstract method"; end;
  end

  class ShutdownEvent < SignalEvent
    def flush?; false; end;
    def shutdown?; true; end;
  end

  class FlushEvent < SignalEvent
    def flush?; true; end;
    def shutdown?; false; end;
  end

  class NoSignal < SignalEvent
    def flush?; false; end;
    def shutdown?; false; end;
  end

  FLUSH = FlushEvent.new
  SHUTDOWN = ShutdownEvent.new
  NO_SIGNAL = NoSignal.new

  class Event
    MSG_BRACKETS_METHOD_MISSING = "Direct event field references (i.e. event['field']) have been disabled in favor of using event get and set methods (e.g. event.get('field')). Please consult the Logstash 5.0 breaking changes documentation for more details.".freeze
    MSG_BRACKETS_EQUALS_METHOD_MISSING = "Direct event field references (i.e. event['field'] = 'value') have been disabled in favor of using event get and set methods (e.g. event.set('field', 'value')). Please consult the Logstash 5.0 breaking changes documentation for more details.".freeze
    RE_BRACKETS_METHOD = /^\[\]$/.freeze
    RE_BRACKETS_EQUALS_METHOD = /^\[\]=$/.freeze

    def method_missing(method_name, *arguments, &block)
      if RE_BRACKETS_METHOD.match(method_name.to_s)
        raise NoMethodError.new(MSG_BRACKETS_METHOD_MISSING)
      end
      if RE_BRACKETS_EQUALS_METHOD.match(method_name.to_s)
        raise NoMethodError.new(MSG_BRACKETS_EQUALS_METHOD_MISSING)
      end
      super
    end
  end
end
