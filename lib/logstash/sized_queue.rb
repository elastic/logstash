# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"

require "thread" # for SizedQueue
class LogStash::SizedQueue < SizedQueue
  # TODO(sissel): Soon will implement push/pop stats, etc
end
