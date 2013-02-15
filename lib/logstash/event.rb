# General event type. 
#
# Basically a light wrapper on top of a hash.
class LogStash::Event
  if ENV["LOGSTASH_SCHEMA"] == "1"
    require "logstash/event_v1"
    include LogStash::EventV1
  else
    require "logstash/event_v0"
    include LogStash::EventV0
  end
end # class LogStash::Event
