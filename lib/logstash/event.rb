# General event type. 
#
# Basically a light wrapper on top of a hash.
class LogStash::Event
  if ENV["LOGSTASH_SCHEMA"] == "0"
    require "logstash/event_v0"
    include LogStash::EventV0
  else
    require "logstash/event_v1"
    include LogStash::EventV1
  end
end # class LogStash::Event
