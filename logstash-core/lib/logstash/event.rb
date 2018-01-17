# encoding: utf-8

require "logstash/namespace"
require "logstash/json"

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
end
