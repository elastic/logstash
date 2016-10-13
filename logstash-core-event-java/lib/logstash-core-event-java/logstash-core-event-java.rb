# encoding: utf-8

require "java"

module LogStash
end

require "logstash-core-event-java_jars"

# local dev setup
classes_dir = File.expand_path("../../../build/classes/main", __FILE__)

if File.directory?(classes_dir)
  # if in local dev setup, add target to classpath
  $CLASSPATH << classes_dir unless $CLASSPATH.include?(classes_dir)
else
  # otherwise use included jar
  begin
    require "logstash-core-event-java/logstash-core-event-java.jar"
  rescue Exception => e
    raise("Error loading logstash-core-event-java/logstash-core-event-java.jar file, cause: #{e.message}")
  end
end

require "jruby_event_ext"
require "jruby_timestamp_ext"
require "logstash/event"
require "logstash/timestamp"
