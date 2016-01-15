# encoding: utf-8

require "java"

module LogStash
end

# local dev setup
classes_dir = File.expand_path("../../../build/classes/main", __FILE__)

if File.directory?(classes_dir)
  # if in local dev setup, add target to classpath
  $CLASSPATH << classes_dir unless $CLASSPATH.include?(classes_dir)
else
  # otherwise use included jar
  raise("TODO build dir not found and no jar file")
end

require "logstash-core-event-java_jars"

require "jruby_event_ext"
require "jruby_timestamp_ext"
require "logstash/event"
require "logstash/timestamp"