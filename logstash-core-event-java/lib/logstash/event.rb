# encoding: utf-8

require "logstash/namespace"
require "logstash/json"
require "logstash/string_interpolation"
require "cabin"

# for backward compatibility, require "logstash/event" is used a lots of places so let's bootstrap the
# Java code loading from here.
# TODO: (colin) I think we should mass replace require "logstash/event" with require "logstash-core-event"
require "logstash-core-event"

module LogStash
  SHUTDOWN = com.logstash.pipeline.Constants.shutdownEvent;
  FLUSH = com.logstash.pipeline.Constants.flushEvent;
end