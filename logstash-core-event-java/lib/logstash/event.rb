# encoding: utf-8

require "logstash/namespace"
require "logstash/json"
require "logstash/string_interpolation"

# transcient pipeline events for normal in-flow signaling as opposed to
# flow altering exceptions. for now having base classes is adequate and
# in the future it might be necessary to refactor using like a BaseEvent
# class to have a common interface for all pileline events to support
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

  FLUSH = FlushEvent.new

  # LogStash::SHUTDOWN is used by plugins
  SHUTDOWN = ShutdownEvent.new
end

# for backward compatibility, require "logstash/event" is used a lots of places so let's bootstrap the
# Java code loading from here.
# TODO: (colin) I think we should mass replace require "logstash/event" with require "logstash-core-event"
require "logstash-core-event"