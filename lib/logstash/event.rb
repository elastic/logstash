# encoding: utf-8
require "jruby_event/jruby_event"

# require "time"
# require "date"
# require "cabin"
require "logstash/namespace"
# require "logstash/util/accessors"
# require "logstash/timestamp"
require "logstash/json"
require "logstash/string_interpolation"

# transcient pipeline events for normal in-flow signaling as opposed to
# flow altering exceptions. for now having base classes is adequate and
# in the future it might be necessary to refactor using like a BaseEvent
# class to have a common interface for all pileline events to support
# eventual queueing persistence for example, TBD.
class LogStash::ShutdownEvent; end
class LogStash::FlushEvent; end

module LogStash
  FLUSH = LogStash::FlushEvent.new

  # LogStash::SHUTDOWN is used by plugins
  SHUTDOWN = LogStash::ShutdownEvent.new
end
