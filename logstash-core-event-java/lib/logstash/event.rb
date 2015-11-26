# encoding: utf-8

require "logstash/namespace"
require "logstash/json"
require "logstash/string_interpolation"
require "cabin"

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

# for backward compatibility, require "logstash/event" is used a lots of places so let's bootstrap the
# Java code loading from here.
# TODO: (colin) I think we should mass replace require "logstash/event" with require "logstash-core-event"
require "logstash-core-event"